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
    /// How many copies of each card adding it adds.
    var copies: (Card.ID) -> Int = { _ in 1 }
    var onIncrementCopies: (Card.ID) -> Void = { _ in }
    var onDecrementCopies: (Card.ID) -> Void = { _ in }
    var onAdd: (Card.ID) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cards) { card in
                    SuggestedCardTile(
                        card: card,
                        addStatus: addStatus(card.id),
                        copies: copies(card.id),
                        onIncrementCopies: { onIncrementCopies(card.id) },
                        onDecrementCopies: { onDecrementCopies(card.id) },
                        onAdd: { onAdd(card.id) }
                    )
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
    var copies = 1
    var onIncrementCopies: () -> Void = {}
    var onDecrementCopies: () -> Void = {}
    var onAdd: () -> Void = {}

    // A trading card's 63 × 88 mm shape.
    private static let imageSize = CGSize(width: 120, height: 168)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            details
            if let addStatus {
                CopiesStepper(
                    copies: copies,
                    range: AddToCollectionViewModel.copiesRange,
                    // The count saved, or being saved, stays as it is.
                    isEnabled: addStatus.canAdd,
                    onIncrement: onIncrementCopies,
                    onDecrement: onDecrementCopies
                )
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

#Preview("Adding copies") {
    let statuses: [AddToCollectionViewModel.Status] = [.notAdded, .adding, .added, .failed]
    let cards = statuses.indices.map { index in
        SuggestedCardPresentation(ChatAnswer.Suggestion(
            card: Card(id: index, name: "Card \(index)", number: "OP01-00\(index)"),
            price: PricePoint(cardID: index, date: .now, price: Money(amount: 1.99, currencyCode: "USD"))
        ))
    }
    SuggestedCardsRow(
        cards: cards,
        addStatus: { statuses[$0] },
        copies: { [1, 3, 3, 9][$0] }
    )
    .padding()
}
#endif
