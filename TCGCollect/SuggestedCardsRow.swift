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

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cards) { card in
                    SuggestedCardTile(card: card)
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

    // A trading card's 63 × 88 mm shape.
    private static let imageSize = CGSize(width: 120, height: 168)

    var body: some View {
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
        .frame(width: Self.imageSize.width, alignment: .leading)
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
#endif
