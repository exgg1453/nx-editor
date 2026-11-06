import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel = ChatViewModel()
    @State private var isPickerPresented = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messageList
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }
                if !viewModel.pendingImages.isEmpty {
                    pendingImagesRow
                }
                inputBar
            }
            .navigationTitle("NX Editör")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clear) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                MediaPicker(selectionLimit: 3) { images in
                    viewModel.addImages(images)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isSending {
                        HStack {
                            ProgressView()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages) { _ in
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            Text("Ask anything or attach a photo or video to get started.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.red.opacity(0.85))
    }

    private var pendingImagesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.pendingImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button {
                            viewModel.removePendingImage(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                isPickerPresented = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.title2)
            }
            .disabled(viewModel.pendingImages.count >= 3)

            TextField("Message", text: $viewModel.input)
                .textFieldStyle(.roundedBorder)

            Button {
                viewModel.send(settings: settings)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled((viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.pendingImages.isEmpty) || viewModel.isSending)
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: Message

    private var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                ForEach(Array(message.images.enumerated()), id: \.offset) { _, dataURL in
                    if let image = dataURL.decodedImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 220, maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(10)
                        .background(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                        .foregroundColor(isUser ? .white : .primary)
                        .cornerRadius(14)
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
