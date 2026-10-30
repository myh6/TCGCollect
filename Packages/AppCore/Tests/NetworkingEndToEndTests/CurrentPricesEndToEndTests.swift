//
//  CurrentPricesEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking

@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CurrentPricesEndToEndTests {

    @Test func loadCurrentPrices_deliversUSDPriceForPricedCard() async throws {
        let prices = try await makeSUT().loadCurrentPrices(for: [luffyAndAceCardID])

        let price = try #require(prices.first)
        #expect(prices.count == 1)
        #expect(price.cardID == luffyAndAceCardID)
        #expect(price.price.currencyCode == "USD")
        #expect(price.price.amount > 0)
    }

    @Test func loadCurrentPrices_deliversNothingForUnknownCard() async throws {
        let prices = try await makeSUT().loadCurrentPrices(for: [-1])

        #expect(prices.isEmpty)
    }

    // MARK: - Helpers
    private let luffyAndAceCardID = 2133087

    private func makeSUT() throws -> CardPriceLoader {
        CurrentPricesComposer.makeRemoteCardPriceLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
