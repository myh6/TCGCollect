//
//  CardOwnershipSection.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import AppCore

struct CardOwnershipSection: View {
    let copies: OwnedCopiesViewModel
    let addControls: AddToCollectionViewModel.Controls

    private static var controlWidth: CGFloat { 120 }

    var body: some View {
        VStack(spacing: 12) {
            ownedCopies
            HStack(spacing: 12) {
                CopiesStepper(
                    copies: addControls.copies,
                    range: AddToCollectionViewModel.copiesRange,
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

    @ViewBuilder
    private var ownedCopies: some View {
        switch copies.copies {
        case .loaded(let count) where count > 0:
            Label("You own ×\(count)", systemImage: "rectangle.stack.fill")
                .font(.subheadline.weight(.semibold))
        case .loaded:
            Text("Not in your collection yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .idle, .loading, .failed:
            EmptyView()
        }
    }
}
