import Foundation

enum DecodingError: Error {
    case notAString
    case invalidString
}

extension URLSessionWebSocketTask.Message {
    func decodeString<T: Decodable>(
        as type: T.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard case let .string(content) = self else {
            throw DecodingError.notAString
        }

        guard let data = content.data(using: .utf8) else {
            throw DecodingError.invalidString
        }

        return try decoder.decode(type, from: data)
    }
}
