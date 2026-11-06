import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var input: String = ""
    @Published var pendingImages: [UIImage] = []
    @Published var isSending: Bool = false
    @Published var errorMessage: String?

    private let imageLimit = 3

    func addImages(_ images: [UIImage]) {
        let available = imageLimit - pendingImages.count
        guard available > 0 else { return }
        pendingImages.append(contentsOf: images.prefix(available))
    }

    func removePendingImage(at index: Int) {
        guard pendingImages.indices.contains(index) else { return }
        pendingImages.remove(at: index)
    }

    func send(settings: SettingsStore) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !pendingImages.isEmpty, !isSending else { return }

        let encoded = pendingImages.compactMap { ImageEncoder.dataURL(from: $0) }
        let promptText = (trimmed.isEmpty && !encoded.isEmpty) ? "What is in this image?" : trimmed

        input = ""
        pendingImages = []
        errorMessage = nil
        messages.append(Message(role: "user", text: promptText, images: encoded))
        isSending = true

        let hasImages = !encoded.isEmpty
        let model = hasImages ? settings.visionModel : settings.model
        let service = ChatService(apiKey: settings.apiKey, baseURL: settings.baseURL, model: model)

        var outgoing = [OutgoingMessage(role: "system", text: settings.systemPrompt, images: [])]
        for (index, message) in messages.enumerated() {
            let isLast = index == messages.count - 1
            outgoing.append(OutgoingMessage(role: message.role, text: message.text, images: isLast ? message.images : []))
        }

        Task {
            do {
                let reply = try await service.send(messages: outgoing)
                messages.append(Message(role: "assistant", text: reply))
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSending = false
        }
    }

    func clear() {
        messages.removeAll()
        pendingImages.removeAll()
        errorMessage = nil
    }
}
