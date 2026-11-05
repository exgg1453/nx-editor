import Foundation

struct ChatMessagePayload: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessagePayload]
    let temperature: Double
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        let message: ChatMessagePayload
    }
    let choices: [Choice]
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

    func send(messages: [ChatMessagePayload]) async throws -> String {
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
        request.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(model: model, messages: messages, temperature: 0.7)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? "The request failed."
            throw ChatServiceError.server(text)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw ChatServiceError.emptyResponse
        }
        return content
    }
}
