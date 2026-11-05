//
//  CollectionValueEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
import Networking

@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CollectionValueEndToEndTests {

    @Test func loadValueHistory_deliversDailyValuesOldestFirstEndingAtCurrentTotal() async throws {
        let history = try await makeSUT().loadValueHistory(of: [luffyAndAceCardID: 2], days: nil)

        #expect(!history.points.isEmpty)
        #expect(history.points.map(\.date) == history.points.map(\.date).sorted())
        #expect(history.currentTotal == history.points.last?.value)
    }

    @Test func loadValueHistory_deliversNothingForUnknownCard() async throws {
        let history = try await makeSUT().loadValueHistory(of: [-1: 1], days: 30)

        #expect(history.currentTotal == nil)
        #expect(history.points.isEmpty)
    }

    // MARK: - Helpers
    private let luffyAndAceCardID = 2133087

    private func makeSUT() throws -> CollectionValueHistoryLoader {
        CollectionValueComposer.makeRemoteCollectionValueHistoryLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
