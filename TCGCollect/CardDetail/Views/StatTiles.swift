//
//  StatTiles.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/11.
//

import SwiftUI

struct StatTiles: View {
    let stats: [DetailStat]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(stats, id: \.label) { stat in
                VStack(spacing: 2) {
                    Text(stat.value)
                        .font(.title3.weight(.semibold).monospacedDigit())
                    Text(stat.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
