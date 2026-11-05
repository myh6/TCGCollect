//
//  CardSetPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import AppCore

nonisolated struct CardSetPresentation: Identifiable, Equatable {
    let id: CardSet.ID
    let name: String
    let details: String
    let iconURL: URL?
    let set: CardSet

    init(_ set: CardSet, locale: Locale = .current) {
        id = set.id
        name = set.name
        let cardCount = String(AttributedString(localized: "^[\(set.cardCount) card](inflect: true)", locale: locale).characters)
        let releaseDate = set.releaseDate?.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale))
        details = [cardCount, releaseDate].compactMap { $0 }.joined(separator: " · ")
        iconURL = set.iconURL
        self.set = set
    }
}
