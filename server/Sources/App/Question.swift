import Vapor

struct Question: Content {
    let id: Int
    let text: String
    let answers: [String]
}

struct QuestionVotes: Codable {
    let id: Int
    let votes: [String: Int]
}

enum QuestionUpdate: Content {
    case question(Question)
    case finished

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

extension Question {
    static let all: [Question] = [
        .init(
            id: 1,
            text: "Have you done programming work related to the app, but not the app itself? Backend doesn't count",
            answers: ["No", "Yes"]
        ),
        .init(
            id: 2,
            text: "Have you ever dealt with Continuous Integration?",
            answers: ["No", "Yes"]
        ),
        .init(
            id: 3,
            text: "Have you felt the need to automate tasks you or your team were doing repeatedly?",
            answers: [
                "No",
                "Yes, but didn't automate",
                "Yes, and automated it"
            ]
        ),
        .init(
            id: 4,
            text: "Have you played with Swift on the Server?",
            answers: [
                "Never",
                "Yes, Vapor",
                "Yes, Hummingbird",
                "Yes, AWS Lambda + Swift",
                "Yes, more than one of the options"
            ]
        ),
        .init(
            id: 5,
            text: "Have you ever edited a Package.swift file?",
            answers: [
                "No",
                "For sure!"
            ]
        ),
    ]
}
