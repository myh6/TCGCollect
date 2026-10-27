//
//  CardSearcher.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Domain

public protocol CardSearcher {
    func search(_ query: String) async throws -> [CardSearchResult]
}
