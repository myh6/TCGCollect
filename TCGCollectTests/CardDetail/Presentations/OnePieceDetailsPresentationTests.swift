//
//  OnePieceDetailsPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct OnePieceDetailsPresentationTests {

    @Test(arguments: [
        (OnePieceDetails.Category.leader, "Leader"),
        (.character, "Character"),
        (.event, "Event"),
        (.stage, "Stage"),
        (.don, "DON!!"),
    ])
    func init_namesCategory(category: OnePieceDetails.Category, expected: String) {
        #expect(makeSUT(category: category).category == expected)
    }

    @Test func init_keepsColorsAndNamesThemInOrder() {
        let sut = makeSUT(colors: [.red, .green])

        #expect(sut.colors == [.red, .green])
        #expect(sut.colorNames == "Red / Green")
    }

    @Test func init_namesEveryColor() {
        let sut = makeSUT(colors: [.red, .green, .blue, .purple, .black, .yellow])

        #expect(sut.colorNames == "Red / Green / Blue / Purple / Black / Yellow")
    }

    @Test func init_hasNoColorNamesWithoutColors() {
        #expect(makeSUT(colors: []).colorNames == nil)
    }

    @Test func init_showsStatsInCardOrder() {
        let sut = makeSUT(cost: 3, power: 4000, counter: 1000, life: 5)

        #expect(sut.stats == [
            .init(label: "Cost", value: "3"),
            .init(label: "Power", value: "4,000"),
            .init(label: "Counter", value: "1,000"),
            .init(label: "Life", value: "5"),
        ])
    }

    @Test func init_leavesOutMissingStats() {
        let sut = makeSUT(cost: 2, power: nil, counter: nil, life: nil)

        #expect(sut.stats == [.init(label: "Cost", value: "2")])
    }

    @Test func init_formatsStatsForLocale() {
        let sut = makeSUT(power: 4000, locale: Locale(identifier: "de_DE"))

        #expect(sut.stats == [.init(label: "Power", value: "4.000")])
    }

    @Test func init_keepsAttributesAndTypesInOrder() {
        let sut = makeSUT(attributes: ["Slash", "Strike"], types: ["FILM", "Straw Hat Crew"])

        #expect(sut.attributes == ["Slash", "Strike"])
        #expect(sut.types == ["FILM", "Straw Hat Crew"])
    }

    @Test func init_hasNoAttributesOrTypesWhenEmpty() {
        let sut = makeSUT(attributes: [], types: [])

        #expect(sut.attributes.isEmpty)
        #expect(sut.types.isEmpty)
    }

    @Test(arguments: ["[Blocker] **You may trash 1 Event**", nil])
    func init_keepsEffect(effect: String?) {
        #expect(makeSUT(effect: effect).effect == effect)
    }

    // MARK: - Helpers
    private func makeSUT(
        category: OnePieceDetails.Category = .character,
        colors: [OnePieceDetails.Color] = [.red],
        cost: Int? = nil,
        power: Int? = nil,
        counter: Int? = nil,
        life: Int? = nil,
        attributes: [String] = [],
        types: [String] = [],
        effect: String? = nil,
        locale: Locale = Locale(identifier: "en_US")
    ) -> OnePieceDetailsPresentation {
        OnePieceDetailsPresentation(
            OnePieceDetails(
                category: category, colors: colors,
                cost: cost, power: power, counter: counter, life: life,
                attributes: attributes, types: types, effect: effect
            ),
            locale: locale
        )
    }
}
