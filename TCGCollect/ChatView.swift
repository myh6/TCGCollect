//
//  ChatView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import SwiftUI
import AppCore

/// One question and its latest answer. A request keeps running until the user cancels it,
/// even when they switch tabs: LLM and tool calls can take a while.
struct ChatView: View {
    let viewModel: ChatViewModel
    // Kept after sending, so the user can see what they asked and edit it.
    @State private var question = ""
    @FocusState private var isQuestionFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .defaultScrollAnchor(.top)
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { isQuestionFocused = false }
            Divider()
            inputBar
                .padding()
        }
        .navigationTitle("Chat")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Ask anything about One Piece TCG", systemImage: "bubble.left.and.text.bubble.right")
        case .loading:
            ProgressView("Thinking…")
                .frame(maxWidth: .infinity)
        case let .loaded(answer):
            Text(answer.text)
                .textSelection(.enabled)
        case let .failed(error):
            Label(error.message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom) {
            TextField("Ask a question…", text: $question, axis: .vertical)
                .lineLimit(1...5)
                .focused($isQuestionFocused)
                .onSubmit(send)
            if viewModel.state == .loading {
                Button("Cancel", systemImage: "stop.circle.fill") {
                    viewModel.cancel()
                }
            } else {
                Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .labelStyle(.iconOnly)
        .font(.title2)
    }

    private func send() {
        // Hide the keyboard so the answer and the tab bar are visible.
        isQuestionFocused = false
        Task { await viewModel.send(question) }
    }
}

/// Shown instead of the chat when the backend isn't configured, e.g. in Release builds for now.
struct ChatUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Chat unavailable",
            systemImage: "bubble.left.and.exclamationmark.bubble.right",
            description: Text("The backend URL or API key is missing from this build.")
        )
        .navigationTitle("Chat")
    }
}

#if DEBUG
/// Answers previews with a fixed result, or never answers when `result` is nil.
private nonisolated struct PreviewLoader: ChatLoader {
    let result: Result<ChatAnswer, Error>?

    func load(question: String) async throws -> ChatAnswer {
        guard let result else {
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
        return try result.get()
    }
}

#Preview("Idle") {
    NavigationStack {
        ChatView(viewModel: ChatViewModel(loader: PreviewLoader(result: nil)))
    }
}

#Preview("Loading") {
    let viewModel = ChatViewModel(loader: PreviewLoader(result: nil))
    NavigationStack {
        ChatView(viewModel: viewModel)
    }
    .task { await viewModel.send("What is a Leader card?") }
}

#Preview("Loaded") {
    let viewModel = ChatViewModel(loader: PreviewLoader(result: .success(ChatAnswer(
        text: "A Leader card starts the game face up and sets your deck's colors. Its life value decides how many cards go into your Life area.",
        suggestions: []
    ))))
    NavigationStack {
        ChatView(viewModel: viewModel)
    }
    .task { await viewModel.send("What is a Leader card?") }
}

#Preview("Failed") {
    let viewModel = ChatViewModel(loader: PreviewLoader(result: .failure(URLError(.notConnectedToInternet))))
    NavigationStack {
        ChatView(viewModel: viewModel)
    }
    .task { await viewModel.send("What is a Leader card?") }
}

#Preview("Unavailable") {
    NavigationStack {
        ChatUnavailableView()
    }
}
#endif
