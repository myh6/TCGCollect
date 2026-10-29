//
//  CardDetailsEndToEndTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import Networking
import Domain

@Suite(.enabled(if: EndToEndEnvironment.isConfigured, "Set E2E_BASE_URL and E2E_API_KEY to run end-to-end tests"))
struct CardDetailsEndToEndTests {

    @Test func loadDetails_deliversOnePieceDetailsFromBackend() async throws {
        let details = try await makeSUT().loadDetails(for: filmCharacterCardID)

        guard case let .onePiece(onePiece) = try #require(details) else { return }
        #expect(onePiece.category == .character)
        #expect(onePiece.colors == [.green])
        #expect(onePiece.cost == 3)
        #expect(onePiece.power == 4000)
        #expect(onePiece.counter == 1000)
        #expect(onePiece.types == ["FILM"])
        #expect(onePiece.effect?.hasPrefix("[Blocker] *(After your opponent declares an attack") == true)
    }

    // MARK: - Helpers
    private let filmCharacterCardID = 675180

    private func makeSUT() throws -> CardDetailsLoader {
        CardDetailsComposer.makeRemoteCardDetailsLoader(
            baseURL: try #require(EndToEndEnvironment.baseURL),
            apiKey: try #require(EndToEndEnvironment.apiKey)
        )
    }
}
