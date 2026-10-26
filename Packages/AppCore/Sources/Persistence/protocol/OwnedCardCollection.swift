//
//  OwnedCardCollection.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

/// Everything that can be done with owned cards, for whoever builds the collection and hands it out.
/// Screens should ask only for the protocol they use, e.g. `OwnedCardSaver` to add a card.
public typealias OwnedCardCollection = OwnedCardLoader & OwnedCardSaver & OwnedCardRemover
