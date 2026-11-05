//
//  EditableOwnedCardTile.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/05.
//

import SwiftUI

struct EditableOwnedCardTile: View {
    let card: OwnedCardPresentation
    let isRemoving: Bool
    let didFailToRemove: Bool
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            OwnedCardTile(card: card)
                .opacity(isRemoving ? 0.4 : 1)
                .jiggling()
                .overlay(alignment: .topTrailing) { removeButton }
            if didFailToRemove {
                Text("Couldn't remove. Try again.")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var removeButton: some View {
        if isRemoving {
            ProgressView()
                .offset(x: 8, y: -8)
        } else {
            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .offset(x: 8, y: -8)
            .accessibilityLabel("Remove \(card.name)")
        }
    }
}

private struct Jiggle: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTiltedRight = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(reduceMotion ? 0 : (isTiltedRight ? 1.5 : -1.5)))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true).delay(.random(in: 0...0.1))) {
                    isTiltedRight = true
                }
            }
    }
}

private extension View {
    func jiggling() -> some View {
        modifier(Jiggle())
    }
}
