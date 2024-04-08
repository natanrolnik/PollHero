import Foundation
import Shared
import SwiftTUI

class ContentView: View {
    private let jsonDecoder = JSONDecoder()

    @State var question: Question?
    @State var votes: [String: Int] = [:]

    init() {
        sendPost("reset")
        registerWebSockets()

        scheduleNext(delay: 3)
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
                .background(.white)

                Spacer()
            }
            Spacer()
        }

    }

    var votesView: some View {
        let sortedVotes = votes.sorted(by: { $0.value > $1.value })
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
        let votesURL = URL(string: "ws://localhost:8080/votes")!
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

        let questionsURL = URL(string: "ws://localhost:8080/questions")!
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
        var request = URLRequest(url: URL(string: "http://localhost:8080/\(path)")!)
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
                self.votes.removeAll()
                self.scheduleNext(delay: 10)
            case .finished:
                exit(0)
                break
            }
        }
    }

    func processVoteMessage(_ message: URLSessionWebSocketTask.Message) {
        guard let votes = try? message.decodeString(as: QuestionVotes.self, using: jsonDecoder) else {
            return
        }

        guard question?.id == votes.id else {
            return
        }

        DispatchQueue.main.async {
            self.votes = votes.votes
        }
    }

    func scheduleNext(delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
            self.sendPost("next")
        }
    }
}
