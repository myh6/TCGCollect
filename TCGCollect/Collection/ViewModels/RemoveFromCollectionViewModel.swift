//
//  RemoveFromCollectionViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class RemoveFromCollectionViewModel {
    enum Status: Equatable {
        case idle
        case removing
        case failed

        var canRemove: Bool { self != .removing }
    }

    private(set) var status = Status.idle

    private let remover: OwnedCardRemover

    init(remover: OwnedCardRemover) {
        self.remover = remover
    }

    func removeNewestCopy(of cardID: Card.ID) async {
        guard status.canRemove else { return }
        status = .removing
        do {
            try await remover.removeNewestCopy(of: cardID)
            status = .idle
        } catch {
            status = .failed
        }
    }
}
