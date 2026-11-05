import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private enum Keys {
        static let apiKey = "groq_api_key"
        static let model = "model"
        static let baseURL = "base_url"
        static let systemPrompt = "system_prompt"
    }

    @Published var apiKey: String {
        didSet { KeychainStore.shared.set(apiKey, for: Keys.apiKey) }
    }

    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Keys.model) }
    }

    @Published var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Keys.baseURL) }
    }

    @Published var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: Keys.systemPrompt) }
    }

    init() {
        self.apiKey = KeychainStore.shared.get(Keys.apiKey) ?? ""
        self.model = UserDefaults.standard.string(forKey: Keys.model) ?? "llama-3.3-70b-versatile"
        self.baseURL = UserDefaults.standard.string(forKey: Keys.baseURL) ?? "https://api.groq.com/openai/v1"
        self.systemPrompt = UserDefaults.standard.string(forKey: Keys.systemPrompt) ?? "You are a helpful assistant."
    }
}
