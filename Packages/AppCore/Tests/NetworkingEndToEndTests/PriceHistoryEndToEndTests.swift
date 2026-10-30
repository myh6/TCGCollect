//
//  PriceHistoryEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking

@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct PriceHistoryEndToEndTests {

    @Test func loadPriceHistory_deliversThisCardsPointsOldestFirst() async throws {
        let points = try await makeSUT().loadPriceHistory(for: [luffyAndAceCardID], days: nil)

        #expect(!points.isEmpty)
        #expect(points.allSatisfy { $0.cardID == luffyAndAceCardID })
        #expect(points.map(\.date) == points.map(\.date).sorted())
    }

    @Test func loadPriceHistory_deliversNothingForUnknownCard() async throws {
        let points = try await makeSUT().loadPriceHistory(for: [-1], days: 30)

        #expect(points.isEmpty)
    }

    // MARK: - Helpers
    private let luffyAndAceCardID = 2133087

    private func makeSUT() throws -> CardPriceHistoryLoader {
        PriceHistoryComposer.makeRemoteCardPriceHistoryLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
