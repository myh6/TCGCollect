//
//  OwnedCardComposer.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation

/// Builds the owned card collection on a SwiftData store file, so callers never depend on SwiftData.
/// Make one per app and share it: Core Data can crash if several new store files are set up at the same moment.
public enum OwnedCardComposer {
    public static func makeLocalOwnedCardCollection(storeURL: URL) throws -> OwnedCardCollection {
        LocalOwnedCardLoader(store: try SwiftDataOwnedCardStore(storeURL: storeURL))
    }
}
