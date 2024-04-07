import Foundation

struct Question: Codable {
    let id: Int
    let text: String
    let answers: [String]
}

struct QuestionVotes: Codable {
    let id: Int
    let votes: [String: Int]
}

enum QuestionUpdate: Codable {
    enum Error: Swift.Error {
        case invalidEnum
    }

    case question(Question)
    case finished

    enum CodingKeys: CodingKey {
        case question
        case finished
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let question = try container.decodeIfPresent(Question.self, forKey: .question) {
            self = .question(question)
        } else if let finished = try? container.decodeIfPresent(Bool.self, forKey: .finished), finished {
            self = .finished
        } else {
            throw Error.invalidEnum
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .question(question):
            try container.encode(question, forKey: .question)
        case .finished:
            try container.encode(true, forKey: .finished)
        }
    }
}
