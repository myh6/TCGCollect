//
//  OwnedCardStore.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

/// Where owned cards are kept. Implementations hide their storage, e.g. SwiftData, behind Domain types.
public protocol OwnedCardStore {
    func retrieveAll() async throws -> [OwnedCard]
}
