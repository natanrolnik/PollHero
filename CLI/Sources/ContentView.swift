import Foundation
import Shared
import SwiftTUI

private let serverHost = "poll-hero-1b16db57f7aa.herokuapp.com"
private let socketScheme = "wss"

// private let serverHost = "localhost:8080"
// private let socketScheme = "ws"

class ContentView: View {
    private let jsonDecoder = JSONDecoder()

    @State var question: Question?
    @State var votes: [String: Int] = [:]

    init() {
        sendPost("reset")
        registerWebSockets()

        scheduleNext(delay: 7)
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                VStack {
                    if let question {
                        Text(question.text)
                        Spacer()
                            .frame(height: 2)
                        votesView
                    } else {
                        Text("Let's start with some warm up questions!")
                            .bold()
                        Text("Right from the CLI!")
                            .bold()
                    }
                }
                .padding()
                .border()
                .background(.red)

                Spacer()
            }
            Spacer()
        }

    }

    var votesView: some View {
        let sortedVotes = votes
            .sorted(by: { $0.value > $1.value })
            .filter { $0.value > 0 }

        let totalVotes = votes.reduce(0) { $0 + $1.value }
        return ForEach(sortedVotes, id: \.key) { answer, count in
            let percent = Int((Float(count) / Float(totalVotes)) * 100)
            let squares = percent / 2
            VStack {
                Text("\(percent)% (\(count)): \(answer)")
                    .bold()
                Text(String(repeatElement("▮", count: squares)))
                Spacer().frame(height: 1)
            }
        }
    }
}

private extension ContentView {
    func registerWebSockets() {
        let votesURL = URL(string: "\(socketScheme)://\(serverHost)/votes")!
        let votesSocket = URLSession.shared.webSocketTask(with: votesURL)

        func votesSocketReceive() {
            votesSocket.receive { result in
                if case let .success(message) = result {
                    self.processVoteMessage(message)
                }

                votesSocketReceive()
            }
        }

        votesSocketReceive()

        votesSocket.resume()

        let questionsURL = URL(string: "\(socketScheme)://\(serverHost)/questions")!
        let questionsSocket = URLSession.shared.webSocketTask(with: questionsURL)

        func questionsSocketReceive() {
            questionsSocket.receive { result in
                if case let .success(message) = result {
                    self.processQuestionMessage(message)
                }

                questionsSocketReceive()
            }
        }

        questionsSocketReceive()

        questionsSocket.resume()
    }

    func sendPost(_ path: String) {
        var request = URLRequest(url: URL(string: "https://\(serverHost)/\(path)")!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request).resume()
    }

    func processQuestionMessage(_ message: URLSessionWebSocketTask.Message) {
        guard let update = try? message.decodeString(as: QuestionUpdate.self, using: jsonDecoder) else {
            return
        }

        DispatchQueue.main.async {
            switch update {
            case let .question(question):
                self.question = question
                self.votes = question.answers.reduce(into: [:]) {
                    $0[$1] = 0
                }
                self.scheduleNext(delay: 12)
            case .finished:
                exit(0)
                break
            }
        }
    }

    func processVoteMessage(_ message: URLSessionWebSocketTask.Message) {
        guard let vote = try? message.decodeString(as: Vote.self, using: jsonDecoder) else {
            return
        }

        guard let question,
              question.id == vote.questionId,
              question.answers.indices.contains(vote.answerIndex) else {
            return
        }

        let answer = question.answers[vote.answerIndex]

        DispatchQueue.main.async {
            var votes = self.votes
            votes[answer] = vote.count
            self.votes = votes
        }
    }

    func scheduleNext(delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
            self.sendPost("next")
        }
    }
}
