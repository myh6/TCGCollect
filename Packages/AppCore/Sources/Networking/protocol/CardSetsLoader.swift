//
//  CardSetsLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

public protocol CardSetsLoader {
    func loadSets(ofGame gameSlug: String) async throws -> [CardSet]
}
