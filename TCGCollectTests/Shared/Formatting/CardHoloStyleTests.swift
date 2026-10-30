//
//  CardHoloStyleTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import Testing
import AppCore
import HoloCard
@testable import TCGCollect

struct CardHoloStyleTests {

    @Test(arguments: ["Foil", "foil", "FOIL"])
    func holoStyle_isFoilForFoilPrinting(printing: String) {
        #expect(makeCard(printing: printing).holoStyle == .foil)
    }

    @Test(arguments: ["Normal", "", "Foil Etched"])
    func holoStyle_isPlainForOtherPrinting(printing: String) {
        #expect(makeCard(printing: printing).holoStyle == .plain)
    }

    @Test func holoStyle_isPlainWithoutPrinting() {
        #expect(makeCard(printing: nil).holoStyle == .plain)
    }

    // MARK: - Helpers
    private func makeCard(printing: String?) -> Card {
        Card(id: 1, name: "Monkey.D.Luffy", printing: printing)
    }
}
