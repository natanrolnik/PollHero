import Redis
import Shared
import Vapor

final class VotesController: RouteCollection {
    private var questionsSockets: [WebSocket] = []
    private var votesCountSocket: WebSocket?

    private let currentQuestionKey: RedisKey = "currentQuestion"
    private var currentQuestionId: Question.ID? {
        get async throws {
            try await redis.get(currentQuestionKey, as: Question.ID.self).get()
        }
    }

    private func setCurrentQuestionId(_ id: Question.ID?) async throws {
        guard let id else {
            _ = try await redis.delete(currentQuestionKey).get()
            return
        }

        _ = try await redis.publish(id, to: "currentQuestion").get()
        try await redis.set(currentQuestionKey, to: id).get()
    }

    private let jsonEncoder = JSONEncoder()

    let redis: Application.Redis

    init(redis: Application.Redis) {
        self.redis = redis

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Task {
                try await self.subscribeToQuestionUpdates()
            }
        }
    }

    func boot(routes: any RoutesBuilder) throws {
        routes.post("vote", use: vote)
        routes.post("next", use: moveToNext)
        routes.post("reset", use: reset)

        routes.webSocket("questions") { [weak self] req, ws in
            Task { [self] in
                try await self?.registerQuestionsSocket(ws, req: req)
            }
        }

        routes.webSocket("votes") { [weak self] req, ws in
            if let existing = self?.votesCountSocket {
                do {
                    try await existing.close()
                } catch {}
            }

            self?.votesCountSocket = ws
            ws.onClose.whenComplete { _ in
                req.logger.debug("Votes socket closed")
                self?.votesCountSocket = nil
            }
        }
    }

    private func registerQuestionsSocket(_ ws: WebSocket, req: Request) async throws {
        questionsSockets.append(ws)

        if let questionId = try await currentQuestionId,
           let question = Question.withId(questionId) {
            try await ws.send(QuestionUpdate.question(question).jsonString(using: jsonEncoder))
        }

        // Remove socket upon close completion
        ws.onClose.whenComplete { [weak self] _ in
            if let index = self?.questionsSockets.firstIndex(where: { $0 === ws }) {
                self?.questionsSockets.remove(at: index)
                req.logger.debug("Question socket closed and removed")
            }
        }
    }

    private var currentQuestionIdSubscription: Question.ID?

    private func subscribeToQuestionUpdates() async throws {
        try await redis.subscribe(
            to: "currentQuestion",
            messageReceiver: { [weak self] publisher, message in
                guard let self, let newQuestionId = message.int else { return }

                let update: QuestionUpdate?
                if newQuestionId == -1 {
                    update = .finished
                } else if let question = Question.withId(newQuestionId) {
                    update = .question(question)
                } else {
                    update = nil
                }

                if let text = try? update?.jsonString(using: jsonEncoder) {
                    self.questionsSockets.forEach { ws in
                        ws.send(text)
                    }
                }

                Task {
                    try await self.subscribeToVotingUpdates(
                        oldQuestionId: self.currentQuestionIdSubscription,
                        newQuestionId: newQuestionId
                    )
                }
            },
            onSubscribe: nil,
            onUnsubscribe: nil
        ).get()
    }

    private func subscribeToVotingUpdates(
        oldQuestionId: Question.ID?,
        newQuestionId: Question.ID?
    ) async throws {
        defer {
            currentQuestionIdSubscription = newQuestionId
        }

        guard let votesCountSocket else { return }

        // Unsubscribe from the old question answer channels
        if let oldQuestionId {
            try await redis.punsubscribe(from: "votes:\(oldQuestionId):*").get()
        }

        // Subscribe to the new question answer channels
        guard let newQuestionId else {
            return
        }

        try await redis.psubscribe(
            to: "votes:\(newQuestionId):*",
            messageReceiver: { [weak votesCountSocket] publisher, message in
                let components = publisher.rawValue.split(separator: ":")
                guard components.count == 3,
                      let questionId = Int(components[1]),
                      let answerIndex = Int(components[2]),
                      let count = message.int else {
                    return
                }

                let vote = Vote(
                    questionId: questionId,
                    answerIndex: answerIndex,
                    count: count
                )
                try? votesCountSocket?.send(vote.jsonString())
            },
            onSubscribe: nil,
            onUnsubscribe: nil
        ).get()
    }

    private func vote(_ req: Request) async throws -> Response {
        let vote = try req.content.decode(VoteRequestPayload.self)
        guard let questionId = try await currentQuestionId,
              vote.questionId == questionId else {
            throw Abort(.badRequest, reason: "Voting is not in progress for this question")
        }

        guard let question = Question.withId(questionId),
              question.answers.indices.contains(vote.index) else {
            throw Abort(.badRequest, reason: "Question not found")
        }

        let key = "votes:\(questionId):\(vote.index)"
        let votesCount = try await redis.increment(.init(stringLiteral: key)).get()
        _ = try await redis.publish(votesCount, to: .init(key)).get()

        return Response(status: .ok)
    }

    private func moveToNext(_ req: Request) async throws -> QuestionUpdate {
        let current = try await currentQuestionId
        if let current, current == Question.all.last?.id {
            try await setCurrentQuestionId(-1)
            return .finished
        }

        let newQuestionId = (current ?? 0) + 1
        try await setCurrentQuestionId(newQuestionId)

        guard let question = Question.withId(newQuestionId) else {
            throw Abort(.internalServerError)
        }

        return QuestionUpdate.question(question)
    }

    private func reset(_ req: Request) async throws -> Response {
        for key in try await redis.scan(matching: "votes:*").get().1 {
            _ = try await redis.delete(.init(stringLiteral: key)).get()
        }

        try await setCurrentQuestionId(nil)

        return Response(status: .ok)
    }
}

private extension Encodable {
    func jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        try String(data: encoder.encode(self), encoding: .utf8) ?? ""
    }
}


private struct VoteRequestPayload: Codable {
    let questionId: Question.ID
    let index: Int
}

private struct EmptyResponse: Content {}

extension Question: Content {}
extension QuestionUpdate: Content {}

private extension Question {
    var answerChannels: [RedisChannelName] {
        answers.indices.map { "votes:\(id):\($0)" }
    }
}
