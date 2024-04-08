import Shared
import Vapor

final class VotesController: RouteCollection {
    private var questionsSockets: [WebSocket] = []
    private var votesCountSocket: WebSocket?

    private var currentQuestionId: Int?
    private var allVotes: [Int: [String: Int]] = [:]

    private let jsonEncoder = JSONEncoder()

    func boot(routes: any RoutesBuilder) throws {
        routes.post("vote", use: vote)
        routes.post("next", use: moveToNext)
        routes.post("reset", use: reset)

        routes.webSocket("questions") { [weak self] req, ws in
            self?.registerQuestionsSocket(ws, req: req)
        }

        routes.webSocket("votes") { [weak self] req, ws in
            do {
                try await self?.votesCountSocket?.close()
            } catch {}

            self?.votesCountSocket = ws
            ws.onClose.whenComplete { _ in
                self?.votesCountSocket = nil
            }
        }
    }

    private func registerQuestionsSocket(_ ws: WebSocket, req: Request) {
        questionsSockets.append(ws)

        if let currentQuestionId,
           let question = Question.all.first(where: { $0.id == currentQuestionId }) {
            try? ws.send(QuestionUpdate.question(question).jsonString(using: jsonEncoder))
        }

        // Remove socket upon close completion
        ws.onClose.whenComplete { [weak self] _ in
            if let index = self?.questionsSockets.firstIndex(where: { $0 === ws }) {
                self?.questionsSockets.remove(at: index)
            }
        }
    }

    private func vote(_ req: Request) async throws -> Response {
        let vote = try req.content.decode(Vote.self)

        guard let currentQuestionId,
              vote.questionId == currentQuestionId else {
            throw Abort(.badRequest, reason: "Voting is not in progress for this question")
        }

        guard let question = Question.all.first(where: { $0.id == currentQuestionId }),
              question.answers.indices.contains(vote.index) else {
            throw Abort(.badRequest, reason: "Question not found")
        }
        
        let answer = question.answers[vote.index]
        var questionVotes = allVotes[question.id] ?? [:]
        var currentAnswerCount = questionVotes[answer] ?? 0
        currentAnswerCount += 1
        questionVotes[answer] = currentAnswerCount
        allVotes[question.id] = questionVotes

        let votes = QuestionVotes(id: question.id, votes: questionVotes)
        try await votesCountSocket?.send(votes.jsonString(using: jsonEncoder))

        return Response(status: .ok)
    }

    private func moveToNext(_ req: Request) async throws -> QuestionUpdate {
        if let current = currentQuestionId, current == Question.all.last?.id {
            currentQuestionId = nil
            try questionsSockets.forEach { ws in
                try ws.send(QuestionUpdate.finished.jsonString(using: jsonEncoder))
            }
            return .finished
        }

        currentQuestionId = (currentQuestionId ?? 0) + 1
        guard let question = Question.all.first(where: { $0.id == currentQuestionId }) else {
            throw Abort(.internalServerError)
        }

        let questionUpdate = QuestionUpdate.question(question)
        let questionString = try questionUpdate.jsonString(using: jsonEncoder)
        questionsSockets.forEach { ws in
            ws.send(questionString)
        }

        return questionUpdate
    }

    private func reset(_ req: Request) async throws -> Response {
        allVotes.removeAll()
        currentQuestionId = 0

        return Response(status: .ok)
    }
}

private struct Vote: Codable {
    let questionId: Int
    let index: Int
}

private struct EmptyResponse: Content {}

private extension Encodable {
    func jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        try String(data: encoder.encode(self), encoding: .utf8) ?? ""
    }
}

extension Question: Content {}
extension QuestionUpdate: Content {}
