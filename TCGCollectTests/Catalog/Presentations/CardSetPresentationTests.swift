//
//  CardSetPresentationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct CardSetPresentationTests {

    @Test func init_usesSetIDNameAndIconURL() {
        let iconURL = URL(string: "https://an-icon.com/set.png")!

        let sut = CardSetPresentation(makeSet(id: 7, name: "Romance Dawn", iconURL: iconURL), locale: enUS)

        #expect(sut.id == 7)
        #expect(sut.name == "Romance Dawn")
        #expect(sut.iconURL == iconURL)
    }

    @Test func init_keepsSetToOpen() {
        let set = makeSet(id: 7, name: "Romance Dawn")

        let sut = CardSetPresentation(set, locale: enUS)

        #expect(sut.set == set)
    }

    @Test func init_usesCardCountAndReleaseDateAsDetails() {
        let releaseDate = Calendar.current.date(from: DateComponents(year: 2022, month: 12, day: 2))!

        let sut = CardSetPresentation(makeSet(cardCount: 156, releaseDate: releaseDate), locale: enUS)

        #expect(sut.details == "156 cards · Dec 2, 2022")
    }

    @Test(arguments: [(0, "0 cards"), (1, "1 card"), (2, "2 cards")])
    func init_usesOnlyCardCountWithoutReleaseDate(cardCount: Int, expected: String) {
        let sut = CardSetPresentation(makeSet(cardCount: cardCount, releaseDate: nil), locale: enUS)

        #expect(sut.details == expected)
    }

    // MARK: - Helpers
    private let enUS = Locale(identifier: "en_US")

    private func makeSet(id: Int = 1, name: String = "a set", cardCount: Int = 1, releaseDate: Date? = nil, iconURL: URL? = nil) -> CardSet {
        CardSet(id: id, name: name, cardCount: cardCount, releaseDate: releaseDate, iconURL: iconURL)
    }
}
