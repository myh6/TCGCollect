//
//  CardSet.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

public struct CardSet: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let cardCount: Int
    public let releaseDate: Date?

    public init(id: Int, name: String, cardCount: Int, releaseDate: Date?) {
        self.id = id
        self.name = name
        self.cardCount = cardCount
        self.releaseDate = releaseDate
    }
}
