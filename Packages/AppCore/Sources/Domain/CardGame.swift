//
//  CardGame.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

public struct CardGame: Equatable, Sendable {
    public let slug: String
    public let name: String

    public init(slug: String, name: String) {
        self.slug = slug
        self.name = name
    }
}
