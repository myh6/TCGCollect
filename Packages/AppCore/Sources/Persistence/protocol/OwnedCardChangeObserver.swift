//
//  OwnedCardChangeObserver.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation

public protocol OwnedCardChangeObserver {
    func changes() -> AsyncStream<Void>
}
