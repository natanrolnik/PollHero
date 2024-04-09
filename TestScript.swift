import Foundation

let questionsURL = URL(string: "wss://poll-hero-1b16db57f7aa.herokuapp.com/questions")!

var allSockets: [URLSessionWebSocketTask] = []

for index in 0..<300 {
    let questionsSocket = URLSession.shared.webSocketTask(with: questionsURL)
    
    func questionsSocketReceive() {
        questionsSocket.receive { result in
            if case let .success(message) = result, (index + 1) % 50 == 0 {
                if case .string = message {
                    print("Got \(index) at \(Date())")
                }
            }
            
            questionsSocketReceive()
        }
    }

    allSockets.append(questionsSocket)
    questionsSocketReceive()
    
    questionsSocket.resume()
}

print("Registered \(allSockets.count) sockets")

let group = DispatchGroup()

let sigIntSource = DispatchSource.makeSignalSource(signal: SIGINT)
sigIntSource.setEventHandler {
    group.leave()
    exit(0)
}
sigIntSource.resume()

group.enter()
group.wait()
