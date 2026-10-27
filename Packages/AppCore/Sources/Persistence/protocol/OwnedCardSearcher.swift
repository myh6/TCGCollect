//
//  OwnedCardSearcher.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation
import Domain

public protocol OwnedCardSearcher {
    /// The owned cards whose card matches `query`, in the order they were added. Nothing for an empty query.
    func search(_ query: String) async throws -> [OwnedCard]
}
