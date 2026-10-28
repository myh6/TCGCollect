//
//  FilteringOwnedCardSearcher.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

/// Searches owned cards by loading them all and keeping the ones that match every word of the query.
/// A personal collection is small enough to filter in memory; a store query can replace this
/// behind `OwnedCardSearcher` if it ever isn't.
public struct FilteringOwnedCardSearcher: OwnedCardSearcher {
    private let loader: OwnedCardLoader

    public init(loader: OwnedCardLoader) {
        self.loader = loader
    }

    public func search(_ query: String) async throws -> [OwnedCard] {
        // Symbols like "&" or "-" don't say which card is meant, so only words with a letter or digit count.
        let words = query.split(whereSeparator: \.isWhitespace)
            .filter { word in word.contains { $0.isLetter || $0.isNumber } }
            .map(String.init)
        guard !words.isEmpty else { return [] }

        return try await loader.load().filter { ownedCard in
            words.allSatisfy { ownedCard.card.matches($0) }
        }
    }
}

private extension Card {
    /// A word matches the whole rarity, or any part of the name, card number, set name or printing, ignoring case.
    /// A one-letter word is in almost every name, so it only matches a whole word there, e.g. the "D" of "Monkey D. Luffy".
    func matches(_ word: String) -> Bool {
        if rarity?.compare(word, options: .caseInsensitive) == .orderedSame {
            return true
        }
        let texts = [name, number, setName, printing].compactMap { $0 }
        if word.count == 1 {
            return texts.contains { $0.containsWholeWord(word) }
        }
        return texts.contains { $0.localizedStandardContains(word) }
    }
}

private extension String {
    func containsWholeWord(_ word: String) -> Bool {
        split { !$0.isLetter && !$0.isNumber }
            .contains { $0.compare(word, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}
