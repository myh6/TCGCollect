//
//  PokemonDetailsSection.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/11.
//

import SwiftUI
import AppCore

struct PokemonDetailsSection: View {
    let details: PokemonDetailsPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            categoryStageAndEnergy
            if !details.stats.isEmpty {
                StatTiles(stats: details.stats)
            }
            if details.weakness != nil || details.resistance != nil {
                weaknessAndResistance
            }
            ForEach(Array(details.attacks.enumerated()), id: \.offset) { _, attack in
                EffectText(markdown: attack)
            }
            if let effect = details.effect {
                EffectText(markdown: effect)
            }
            if let flavorText = details.flavorText {
                Text(flavorText)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryStageAndEnergy: some View {
        HStack(spacing: 12) {
            CapsuleBadge(details.category, font: .subheadline.weight(.semibold))
            if let stage = details.stage {
                Text(stage)
                    .font(.subheadline)
            }
            HStack(spacing: 4) {
                ForEach(details.energyTypes, id: \.self) { energy in
                    Circle()
                        .fill(energy.swatch)
                        .overlay(Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1))
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityHidden(true)
            if let energyNames = details.energyNames {
                Text(energyNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weaknessAndResistance: some View {
        HStack(alignment: .top, spacing: 24) {
            if let weakness = details.weakness {
                labeled("Weakness", weakness)
            }
            if let resistance = details.resistance {
                labeled("Resistance", resistance)
            }
        }
    }

    private func labeled(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

private extension PokemonDetails.EnergyType {
    var swatch: Color {
        switch self {
        case .grass: .green
        case .fire: .red
        case .water: .blue
        case .lightning: .yellow
        case .psychic: .purple
        case .fighting: .orange
        case .darkness: .black
        case .metal: .gray
        case .fairy: .pink
        case .dragon: .brown
        case .colorless: .white
        }
    }
}
