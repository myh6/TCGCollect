//
//  OwnedCardCopyCounter.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Domain

public protocol OwnedCardCopyCounter {
    func countCopies(of cardID: Card.ID) async throws -> Int
}
