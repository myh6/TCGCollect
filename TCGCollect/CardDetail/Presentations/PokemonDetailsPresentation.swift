//
//  PokemonDetailsPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/11.
//

import Foundation
import AppCore

nonisolated struct PokemonDetailsPresentation: Equatable {
    let category: String
    let stage: String?
    let energyTypes: [PokemonDetails.EnergyType]
    let energyNames: String?
    let stats: [DetailStat]
    let weakness: String?
    let resistance: String?
    let attacks: [String]
    let effect: String?
    let flavorText: String?

    init(_ details: PokemonDetails, locale: Locale = .current) {
        category = details.category.name
        stage = details.stage
        energyTypes = details.energyTypes
        energyNames = details.energyTypes.isEmpty ? nil : details.energyTypes.map(\.name).joined(separator: " / ")
        stats = [
            (String(localized: "HP"), details.hp),
            (String(localized: "Retreat"), details.retreatCost),
        ].compactMap { label, value in
            value.map { DetailStat(label: label, value: $0.formatted(.number.locale(locale))) }
        }
        weakness = details.weakness.map(Self.namingEnergy)
        resistance = details.resistance.map(Self.namingEnergy)
        attacks = details.attacks
        effect = details.effect
        flavorText = details.flavorText
    }

    private static func namingEnergy(in text: String) -> String {
        guard let match = text.wholeMatch(of: /([A-Z])([x×+\-])?(\d+)?/),
              let energy = PokemonDetails.EnergyType(code: match.1) else { return text }
        let sign = match.2.map { $0 == "x" ? "×" : $0 == "-" ? "−" : String($0) } ?? ""
        let amount = match.3.map(String.init) ?? ""
        return sign.isEmpty && amount.isEmpty ? energy.name : "\(energy.name) \(sign)\(amount)"
    }
}

private nonisolated extension PokemonDetails.Category {
    var name: String {
        switch self {
        case .pokemon: String(localized: "Pokémon")
        case .item: String(localized: "Item")
        case .supporter: String(localized: "Supporter")
        case .stadium: String(localized: "Stadium")
        case .energy: String(localized: "Energy")
        }
    }
}

private nonisolated extension PokemonDetails.EnergyType {
    init?(code: Substring) {
        switch code {
        case "G": self = .grass
        case "R": self = .fire
        case "W": self = .water
        case "L": self = .lightning
        case "P": self = .psychic
        case "F": self = .fighting
        case "D": self = .darkness
        case "M": self = .metal
        case "Y": self = .fairy
        case "N": self = .dragon
        case "C": self = .colorless
        default: return nil
        }
    }

    var name: String {
        switch self {
        case .grass: String(localized: "Grass")
        case .fire: String(localized: "Fire")
        case .water: String(localized: "Water")
        case .lightning: String(localized: "Lightning")
        case .psychic: String(localized: "Psychic")
        case .fighting: String(localized: "Fighting")
        case .darkness: String(localized: "Darkness")
        case .metal: String(localized: "Metal")
        case .fairy: String(localized: "Fairy")
        case .dragon: String(localized: "Dragon")
        case .colorless: String(localized: "Colorless")
        }
    }
}
