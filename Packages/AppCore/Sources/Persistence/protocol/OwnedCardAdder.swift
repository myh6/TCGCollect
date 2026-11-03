//
//  OwnedCardAdder.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Domain

public protocol OwnedCardAdder {
    func addCopies(of card: Card, count: Int) async throws
}
