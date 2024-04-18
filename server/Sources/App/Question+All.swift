import Shared

extension Question {
    static let all: [Question] = [
        Question(
            id: 1,
            text: "Have you done programming work related to the app, but not the app itself?",
            answers: ["No", "Yes"]
        ),
        Question(
            id: 2,
            text: "Have you ever dealt with Continuous Integration?",
            answers: ["No", "Yes"]
        ),
        Question(
            id: 3,
            text: "Have you felt the need to automate tasks you or your team were doing repeatedly?",
            answers: [
                "No",
                "Yes, but didn't automate",
                "Yes, and automated it"
            ]
        ),
        Question(
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
        Question(
            id: 5,
            text: "Have you ever edited a Package.swift file?",
            answers: [
                "No",
                "For sure!"
            ]
        ),
    ]

    static func withId(_ id: Question.ID) -> Self? {
        Self.all.first { $0.id == id }
    }
}
