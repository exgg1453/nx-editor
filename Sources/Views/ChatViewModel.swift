import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var input: String = ""
    @Published var isSending: Bool = false
    @Published var errorMessage: String?

    func send(settings: SettingsStore) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        input = ""
        errorMessage = nil
        messages.append(Message(role: "user", text: trimmed))
        isSending = true

        let service = ChatService(apiKey: settings.apiKey, baseURL: settings.baseURL, model: settings.model)

        var payload = [ChatMessagePayload(role: "system", content: settings.systemPrompt)]
        payload.append(contentsOf: messages.map { ChatMessagePayload(role: $0.role, content: $0.text) })

        Task {
            do {
                let reply = try await service.send(messages: payload)
                messages.append(Message(role: "assistant", text: reply))
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSending = false
        }
    }

    func clear() {
        messages.removeAll()
        errorMessage = nil
    }
}
