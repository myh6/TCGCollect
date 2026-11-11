//
//  PokemonDetailsPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/11.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct PokemonDetailsPresentationTests {

    @Test(arguments: [
        (PokemonDetails.Category.pokemon, "Pokémon"),
        (.item, "Item"),
        (.supporter, "Supporter"),
        (.stadium, "Stadium"),
        (.energy, "Energy"),
    ])
    func init_namesCategory(category: PokemonDetails.Category, expected: String) {
        #expect(makeSUT(category: category).category == expected)
    }

    @Test(arguments: ["Basic", nil])
    func init_keepsStage(stage: String?) {
        #expect(makeSUT(stage: stage).stage == stage)
    }

    @Test func init_keepsEnergyTypesAndNamesThemInOrder() {
        let sut = makeSUT(energyTypes: [.water, .psychic])

        #expect(sut.energyTypes == [.water, .psychic])
        #expect(sut.energyNames == "Water / Psychic")
    }

    @Test func init_namesEveryEnergyType() {
        let sut = makeSUT(energyTypes: [.grass, .fire, .water, .lightning, .psychic, .fighting, .darkness, .metal, .fairy, .dragon, .colorless])

        #expect(sut.energyNames == "Grass / Fire / Water / Lightning / Psychic / Fighting / Darkness / Metal / Fairy / Dragon / Colorless")
    }

    @Test func init_hasNoEnergyNamesWithoutEnergyTypes() {
        #expect(makeSUT(energyTypes: []).energyNames == nil)
    }

    @Test func init_showsHPAndRetreatCostAsStats() {
        let sut = makeSUT(hp: 1200, retreatCost: 2)

        #expect(sut.stats == [
            .init(label: "HP", value: "1,200"),
            .init(label: "Retreat", value: "2"),
        ])
    }

    @Test func init_leavesOutMissingStats() {
        #expect(makeSUT(hp: nil, retreatCost: 0).stats == [.init(label: "Retreat", value: "0")])
        #expect(makeSUT(hp: nil, retreatCost: nil).stats.isEmpty)
    }

    @Test func init_formatsStatsForLocale() {
        let sut = makeSUT(hp: 1200, locale: Locale(identifier: "de_DE"))

        #expect(sut.stats == [.init(label: "HP", value: "1.200")])
    }

    @Test(arguments: [
        ("Px2", "Psychic ×2"),
        ("W×2", "Water ×2"),
        ("F-30", "Fighting −30"),
        ("G+20", "Grass +20"),
        ("R", "Fire"),
        ("L", "Lightning"),
        ("D", "Darkness"),
        ("M", "Metal"),
        ("Y", "Fairy"),
        ("N", "Dragon"),
        ("C", "Colorless"),
        ("Fire x2", "Fire x2"),
        ("Qx2", "Qx2"),
    ])
    func init_namesTheEnergyOfWeaknessAndResistance(text: String, expected: String) {
        let sut = makeSUT(weakness: text, resistance: text)

        #expect(sut.weakness == expected)
        #expect(sut.resistance == expected)
    }

    @Test func init_hasNoWeaknessOrResistanceWhenMissing() {
        let sut = makeSUT(weakness: nil, resistance: nil)

        #expect(sut.weakness == nil)
        #expect(sut.resistance == nil)
    }

    @Test func init_keepsAttacksEffectAndFlavorText() {
        let sut = makeSUT(attacks: ["[F] Thrash (20+)", "[C] Tackle (10)"], effect: "Draw 3 cards.", flavorText: "A flavor text.")

        #expect(sut.attacks == ["[F] Thrash (20+)", "[C] Tackle (10)"])
        #expect(sut.effect == "Draw 3 cards.")
        #expect(sut.flavorText == "A flavor text.")
    }

    // MARK: - Helpers
    private func makeSUT(
        category: PokemonDetails.Category = .pokemon,
        stage: String? = nil,
        hp: Int? = nil,
        energyTypes: [PokemonDetails.EnergyType] = [],
        attacks: [String] = [],
        weakness: String? = nil,
        resistance: String? = nil,
        retreatCost: Int? = nil,
        effect: String? = nil,
        flavorText: String? = nil,
        locale: Locale = Locale(identifier: "en_US")
    ) -> PokemonDetailsPresentation {
        PokemonDetailsPresentation(
            PokemonDetails(
                category: category, stage: stage, hp: hp, energyTypes: energyTypes, attacks: attacks,
                weakness: weakness, resistance: resistance, retreatCost: retreatCost,
                effect: effect, flavorText: flavorText
            ),
            locale: locale
        )
    }
}
