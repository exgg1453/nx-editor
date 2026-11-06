import Foundation

struct OutgoingMessage {
    let role: String
    let text: String
    let images: [String]
}

enum ChatServiceError: LocalizedError {
    case missingApiKey
    case invalidBaseURL
    case emptyResponse
    case transient(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Please add your Groq API key in Settings."
        case .invalidBaseURL:
            return "The base URL in Settings is not valid."
        case .emptyResponse:
            return "The server returned an empty response."
        case .transient(let message):
            return message
        case .server(let message):
            return message
        }
    }
}

struct ChatService {
    let apiKey: String
    let baseURL: String
    let model: String

    private let maxAttempts = 4

    func send(messages: [OutgoingMessage]) async throws -> String {
        var attempt = 0
        while true {
            do {
                return try await performRequest(messages: messages)
            } catch let ChatServiceError.transient(message) {
                attempt += 1
                if attempt >= maxAttempts {
                    throw ChatServiceError.server(message)
                }
                let seconds = pow(2.0, Double(attempt - 1))
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    private func performRequest(messages: [OutgoingMessage]) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw ChatServiceError.missingApiKey }

        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedBase + "/chat/completions") else {
            throw ChatServiceError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        var jsonMessages: [[String: Any]] = []
        for message in messages {
            if message.images.isEmpty {
                jsonMessages.append(["role": message.role, "content": message.text])
            } else {
                var parts: [[String: Any]] = [["type": "text", "text": message.text]]
                for imageURL in message.images {
                    parts.append(["type": "image_url", "image_url": ["url": imageURL]])
                }
                jsonMessages.append(["role": message.role, "content": parts])
            }
        }

        let payload: [String: Any] = [
            "model": model,
            "messages": jsonMessages,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? "The request failed."
            if http.statusCode == 429 || (500 ... 599).contains(http.statusCode) {
                throw ChatServiceError.transient(text)
            }
            throw ChatServiceError.server(text)
        }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let first = choices.first,
            let messageObject = first["message"] as? [String: Any],
            let content = messageObject["content"] as? String
        else {
            throw ChatServiceError.emptyResponse
        }
        return content
    }
}
