//
//  CardSetPageLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Domain

public protocol CardSetPageLoader {
    func loadCards(inSet setID: CardSet.ID, offset: Int) async throws -> CardSetPage
}
