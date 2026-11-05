//
//  CardGamesLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

public protocol CardGamesLoader {
    func loadGames() async throws -> [CardGame]
}
