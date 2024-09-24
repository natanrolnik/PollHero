import Foundation

func delayedStream(delay: TimeInterval) -> AsyncStream<Void> {
    AsyncStream { continuation in
        func recursiveCall() {
            continuation.yield(()) // Produce the value

            Task {
                try await Task.sleep(for: .milliseconds(delay * 1000))
                recursiveCall()
            }
        }

        Task {
            try await Task.sleep(for: .milliseconds(delay * 1000))
            recursiveCall()
        }

        continuation.onTermination = { _ in }
    }
}
