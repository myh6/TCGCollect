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
    struct Suggestion: Identifiable {
        let card: SuggestedCardPresentation
        var addControls: AddToCollectionViewModel.Controls?
        var id: Card.ID { card.id }
    }

    let suggestions: [Suggestion]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(suggestions) { suggestion in
                    SuggestedCardTile(card: suggestion.card, addControls: suggestion.addControls)
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
    var addControls: AddToCollectionViewModel.Controls?

    // A trading card's 63 × 88 mm shape.
    private static let imageSize = CGSize(width: 120, height: 168)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(value: card.card) {
                details
            }
            .buttonStyle(.plain)
            if let addControls {
                CopiesStepper(
                    copies: addControls.copies,
                    range: AddToCollectionViewModel.copiesRange,
                    // The count saved, or being saved, stays as it is.
                    isEnabled: addControls.status.canAdd,
                    onIncrement: addControls.incrementCopies,
                    onDecrement: addControls.decrementCopies
                )
                AddToCollectionButton(status: addControls.status, action: addControls.add)
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
    SuggestedCardsRow(suggestions: cards.map { SuggestedCardsRow.Suggestion(card: $0) })
        .padding()
}

#Preview("Adding copies") {
    let statuses: [AddToCollectionViewModel.Status] = [.notAdded, .adding, .added, .failed]
    let copies = [1, 3, 3, 9]
    let suggestions = statuses.indices.map { index in
        SuggestedCardsRow.Suggestion(
            card: SuggestedCardPresentation(ChatAnswer.Suggestion(
                card: Card(id: index, name: "Card \(index)", number: "OP01-00\(index)"),
                price: PricePoint(cardID: index, date: .now, price: Money(amount: 1.99, currencyCode: "USD"))
            )),
            addControls: AddToCollectionViewModel.Controls(
                status: statuses[index],
                copies: copies[index],
                incrementCopies: {},
                decrementCopies: {},
                add: {}
            )
        )
    }
    SuggestedCardsRow(suggestions: suggestions)
    .padding()
}
#endif
