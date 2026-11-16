//
//  ChatView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import SwiftUI
import AppCore

/// The conversation so far. A request keeps running until the user cancels it,
/// even when they switch tabs: LLM and tool calls can take a while.
struct ChatView: View {
    let viewModel: ChatViewModel
    /// nil when there's no collection to add to, so suggested cards show no add button.
    var addToCollection: AddToCollectionViewModel? = nil
    @State private var question = ""
    @FocusState private var isQuestionFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.turns.isEmpty {
                ContentUnavailableView("Ask anything about One Piece TCG", systemImage: "bubble.left.and.text.bubble.right")
                    .contentShape(Rectangle())
                    .onTapGesture { isQuestionFocused = false }
            } else {
                conversation
            }
            Divider()
            inputBar
                .padding()
        }
        .navigationTitle("Chat")
    }

    private var conversation: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.turns) { turn in
                    ChatTurnView(turn: turn, addToCollection: addToCollection) {
                        Task { await viewModel.retry(turn) }
                    }
                }
            }
            .padding()
            .scrollTargetLayout()
        }
        .defaultScrollAnchor(.bottom)
        .scrollPosition(id: .constant(viewModel.turns.last?.id), anchor: .bottom)
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isQuestionFocused = false }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom) {
            TextField("Ask a question…", text: $question, axis: .vertical)
                .lineLimit(1...5)
                .focused($isQuestionFocused)
                .onSubmit(send)
            if viewModel.isWaitingForAnswer {
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
        guard !viewModel.isWaitingForAnswer else { return }
        // Hide the keyboard so the answer and the tab bar are visible.
        isQuestionFocused = false
        let sentQuestion = question
        question = ""
        Task { await viewModel.send(sentQuestion) }
    }
}

/// One question as a bubble on the right, with its reply under it.
private struct ChatTurnView: View {
    let turn: ChatViewModel.Turn
    let addToCollection: AddToCollectionViewModel?
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(turn.question)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.tint.opacity(0.15), in: .rect(cornerRadius: 18))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.leading, 48)
            reply
        }
    }

    @ViewBuilder
    private var reply: some View {
        switch turn.reply {
        case .waiting:
            ProgressView("Thinking…")
                .frame(maxWidth: .infinity)
        case let .answered(answer):
            VStack(alignment: .leading, spacing: 16) {
                Text(answer.text)
                    .textSelection(.enabled)
                if !answer.suggestions.isEmpty {
                    SuggestedCardsRow(suggestions: answer.suggestions.map { suggestion in
                        SuggestedCardsRow.Suggestion(
                            card: SuggestedCardPresentation(suggestion),
                            addControls: addToCollection?.controls(for: suggestion.card)
                        )
                    })
                }
            }
        case let .failed(error):
            unanswered(Label(error.message, systemImage: "exclamationmark.triangle").foregroundStyle(.red))
        case .cancelled:
            unanswered(Label("Cancelled", systemImage: "stop.circle").foregroundStyle(.secondary))
        }
    }

    private func unanswered(_ label: some View) -> some View {
        HStack {
            label
            Spacer()
            Button("Retry", systemImage: "arrow.clockwise", action: retry)
                .buttonStyle(.bordered)
        }
        .font(.subheadline)
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
private nonisolated struct PreviewLoader: ConversationLoader {
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
        suggestions: [
            Card(id: 1, name: "Monkey.D.Luffy", number: "OP01-024", rarity: "L"),
            Card(id: 2, name: "Roronoa Zoro", number: "OP01-001", rarity: "L"),
        ].map { card in
            ChatAnswer.Suggestion(card: card, price: PricePoint(cardID: card.id, date: .now, price: Money(amount: 4.99, currencyCode: "USD")))
        }
    ))))
    NavigationStack {
        ChatView(viewModel: viewModel)
    }
    .task { await viewModel.send("What is a Leader card?") }
}

#Preview("Conversation") {
    let viewModel = ChatViewModel(loader: PreviewLoader(result: .success(ChatAnswer(
        text: "A Leader card starts the game face up and sets your deck's colors.",
        suggestions: []
    ))))
    NavigationStack {
        ChatView(viewModel: viewModel)
    }
    .task {
        await viewModel.send("What is a Leader card?")
        await viewModel.send("How many can I have in a deck?")
    }
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
