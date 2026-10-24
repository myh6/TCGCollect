//
//  SuggestedCardsRow.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import SwiftUI
import AppCore

/// The cards a chat answer refers to, in the order the backend sent them.
struct SuggestedCardsRow: View {
    let cards: [SuggestedCardPresentation]
    /// How adding each card to the collection is going, or nil to show no add button, e.g. without a collection.
    var addStatus: (Card.ID) -> AddToCollectionViewModel.Status? = { _ in nil }
    var onAdd: (Card.ID) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cards) { card in
                    SuggestedCardTile(card: card, addStatus: addStatus(card.id)) {
                        onAdd(card.id)
                    }
                }
            }
        }
        // Let tiles scroll into the screen's padding instead of being cut off at it.
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
    }
}

struct SuggestedCardTile: View {
    let card: SuggestedCardPresentation
    var addStatus: AddToCollectionViewModel.Status?
    var onAdd: () -> Void = {}

    // A trading card's 63 × 88 mm shape.
    private static let imageSize = CGSize(width: 120, height: 168)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            details
            if let addStatus {
                AddToCollectionButton(status: addStatus, action: onAdd)
            }
        }
        .frame(width: Self.imageSize.width, alignment: .leading)
    }

    // Read as one element by VoiceOver, apart from the button so it stays its own control.
    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardImageView(url: card.imageURL)
                .frame(width: Self.imageSize.width, height: Self.imageSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(card.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            if let details = card.details {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(card.price)
                .font(.caption.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }
}

struct AddToCollectionButton: View {
    let status: AddToCollectionViewModel.Status
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch status {
            case .notAdded:
                Label("Add", systemImage: "plus")
            case .adding:
                ProgressView()
                    .controlSize(.mini)
                    .accessibilityLabel("Adding")
            case .added:
                Label("Added", systemImage: "checkmark")
            case .failed:
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(status == .failed ? .red : nil)
        .disabled(status == .adding || status == .added)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    let cards = [
        Card(id: 1, name: "Monkey.D.Luffy", number: "OP01-024", rarity: "L"),
        Card(id: 2, name: "Roronoa Zoro, a very long card name", number: "OP01-001", rarity: "SR"),
        Card(id: 3, name: "Nami"),
    ].enumerated().map { index, card in
        SuggestedCardPresentation(ChatAnswer.Suggestion(
            card: card,
            price: PricePoint(cardID: card.id, date: .now, price: Money(amount: Decimal(index) * 12.5 + 0.99, currencyCode: "USD"))
        ))
    }
    SuggestedCardsRow(cards: cards)
        .padding()
}
#endif
