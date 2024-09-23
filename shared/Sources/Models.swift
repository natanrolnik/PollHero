import Foundation

public struct Question: Codable, Identifiable {
    public let id: Int
    public let text: String
    public let answers: [String]

    public init(id: Int, text: String, answers: [String]) {
        self.id = id
        self.text = text
        self.answers = answers
    }
}

public struct Votes: Codable {
    public let questionId: Question.ID
    public let votes: [Int: Int]

    public init(questionId: Question.ID, _ votes: [Int : Int]) {
        self.questionId = questionId
        self.votes = votes
    }
}

public struct Vote: Codable {
    public let questionId: Question.ID
    public let answerIndex: Int
    public let count: Int

    public init(questionId: Question.ID, answerIndex: Int, count: Int) {
        self.questionId = questionId
        self.answerIndex = answerIndex
        self.count = count
    }
}

public enum QuestionUpdate: Codable {
    enum Error: Swift.Error {
        case invalidEnum
    }

    case idle
    case question(Question)
    case finished

    enum CodingKeys: CodingKey {
        case idle
        case question
        case finished
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let question = try container.decodeIfPresent(Question.self, forKey: .question) {
            self = .question(question)
        } else if let finished = try? container.decodeIfPresent(Bool.self, forKey: .finished), finished {
            self = .finished
        } else if let idle = try? container.decodeIfPresent(Bool.self, forKey: .idle), idle {
            self = .idle
        } else {
            throw Error.invalidEnum
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .question(question):
            try container.encode(question, forKey: .question)
        case .finished:
            try container.encode(true, forKey: .finished)
        case .idle:
            try container.encode(true, forKey: .idle)
        }
    }

    public var question: Question? {
        switch self {
        case let .question(question): question
        case .finished, .idle: nil
        }
    }
}
