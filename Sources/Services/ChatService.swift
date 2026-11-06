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
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Please add your Groq API key in Settings."
        case .invalidBaseURL:
            return "The base URL in Settings is not valid."
        case .emptyResponse:
            return "The server returned an empty response."
        case .server(let message):
            return message
        }
    }
}

struct ChatService {
    let apiKey: String
    let baseURL: String
    let model: String

    func send(messages: [OutgoingMessage]) async throws -> String {
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
