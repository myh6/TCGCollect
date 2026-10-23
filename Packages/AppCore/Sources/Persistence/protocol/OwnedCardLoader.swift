//
//  OwnedCardLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

public protocol OwnedCardLoader {
    /// The owned cards in the order they were added.
    func load() async throws -> [OwnedCard]
}
