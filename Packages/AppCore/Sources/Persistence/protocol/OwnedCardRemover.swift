//
//  OwnedCardRemover.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import Domain

public protocol OwnedCardRemover {
    func remove(ownedCardID: OwnedCard.ID) async throws
}
