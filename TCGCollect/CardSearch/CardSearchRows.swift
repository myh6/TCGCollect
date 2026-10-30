//
//  CardSearchRows.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

struct OwnedCardGroupRow: View {
    let card: OwnedCardGroupPresentation

    var body: some View {
        CardRow(name: card.name, details: card.details, imageURL: card.imageURL) {
            Text(card.copies)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }
}

struct OnlineCardRow: View {
    let card: OnlineCardPresentation
    var addControls: AddToCollectionViewModel.Controls?

    // As wide as a chat tile, which fits "− 9 +" and "Added" on one line.
    private static var controlWidth: CGFloat { 120 }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            NavigationLink(value: card.card) {
                CardRow(name: card.name, details: card.details, imageURL: card.imageURL) {
                    Text(card.price)
                        .font(.subheadline.monospacedDigit())
                }
            }
            .buttonStyle(.plain)
            if let addControls {
                HStack(spacing: 12) {
                    CopiesStepper(
                        copies: addControls.copies,
                        range: AddToCollectionViewModel.copiesRange,
                        // The count saved, or being saved, stays as it is.
                        isEnabled: addControls.status.canAdd,
                        onIncrement: addControls.incrementCopies,
                        onDecrement: addControls.decrementCopies
                    )
                    .frame(width: Self.controlWidth)
                    AddToCollectionButton(status: addControls.status, action: addControls.add)
                        .lineLimit(1)
                        .frame(width: Self.controlWidth)
                }
            }
        }
    }
}

/// A card's image, name and details, with something at the trailing edge, e.g. its price.
struct CardRow<Trailing: View>: View {
    let name: String
    let details: String?
    let imageURL: URL?
    @ViewBuilder let trailing: () -> Trailing

    // A trading card's 63 × 88 mm shape.
    private static var imageSize: CGSize { CGSize(width: 44, height: 62) }

    var body: some View {
        HStack(spacing: 12) {
            CardImageView(url: imageURL)
                .frame(width: Self.imageSize.width, height: Self.imageSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                if let details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing()
        }
        .accessibilityElement(children: .combine)
    }
}
