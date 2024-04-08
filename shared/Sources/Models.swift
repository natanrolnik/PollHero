import Foundation

public struct Question: Codable {
    public let id: Int
    public let text: String
    public let answers: [String]

    public init(id: Int, text: String, answers: [String]) {
        self.id = id
        self.text = text
        self.answers = answers
    }
}

public struct QuestionVotes: Codable {
    public let id: Int
    public let votes: [String: Int]

    public init(id: Int, votes: [String : Int]) {
        self.id = id
        self.votes = votes
    }
}

public enum QuestionUpdate: Codable {
    enum Error: Swift.Error {
        case invalidEnum
    }

    case question(Question)
    case finished

    enum CodingKeys: CodingKey {
        case question
        case finished
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let question = try container.decodeIfPresent(Question.self, forKey: .question) {
            self = .question(question)
        } else if let finished = try? container.decodeIfPresent(Bool.self, forKey: .finished), finished {
            self = .finished
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
        }
    }
}
