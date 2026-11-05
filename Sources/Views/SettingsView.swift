import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Groq API Key"), footer: Text("Get a free key from console.groq.com and paste it here. It is stored only on this device.")) {
                    SecureField("gsk_...", text: $settings.apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Model")) {
                    TextField("Model", text: $settings.model)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Base URL"), footer: Text("OpenAI compatible endpoint. Change this to use another provider.")) {
                    TextField("https://api.groq.com/openai/v1", text: $settings.baseURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }

                Section(header: Text("System Prompt")) {
                    TextEditor(text: $settings.systemPrompt)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}
