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
    public let iconURL: URL?

    public init(id: Int, name: String, cardCount: Int, releaseDate: Date?, iconURL: URL?) {
        self.id = id
        self.name = name
        self.cardCount = cardCount
        self.releaseDate = releaseDate
        self.iconURL = iconURL
    }
}
