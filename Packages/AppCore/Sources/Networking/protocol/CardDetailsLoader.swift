//
//  CardDetailsLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

public protocol CardDetailsLoader {
    func loadDetails(for cardID: Card.ID) async throws -> GameDetails?
}
