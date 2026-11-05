//
//  CardTile.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import SwiftUI

struct CardTile<Footer: View>: View {
    let name: String
    let details: String?
    let imageURL: URL?
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardImageView(url: imageURL)
                // A trading card's 63 × 88 mm shape, filling the column's width.
                .aspectRatio(63.0 / 88.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            if let details {
                Text(details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            footer()
        }
        .accessibilityElement(children: .combine)
    }
}

extension CardTile where Footer == EmptyView {
    init(name: String, details: String?, imageURL: URL?) {
        self.init(name: name, details: details, imageURL: imageURL) { EmptyView() }
    }
}
