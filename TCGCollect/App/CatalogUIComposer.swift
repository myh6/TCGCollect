//
//  CatalogUIComposer.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import AppCore

enum CatalogUIComposer {
    static func makeGamesList(loader: CardGamesLoader) -> CatalogListViewModel<CardGame> {
        CatalogListViewModel(load: loader.loadGames)
    }

    static func makeSetsList(of game: CardGame, loader: CardSetsLoader) -> CatalogListViewModel<CardSet> {
        CatalogListViewModel {
            try await loader.loadSets(ofGame: game.slug)
        }
    }
}
