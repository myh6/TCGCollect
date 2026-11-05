//
//  CollectionEditViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/05.
//

import Foundation
import Observation
import AppCore

@MainActor
@Observable
final class CollectionEditViewModel {
    private(set) var isEditing = false
    private(set) var removingCopies = Set<OwnedCard.ID>()
    private(set) var failedCopy: OwnedCard.ID?

    private let remover: OwnedCardRemover

    init(remover: OwnedCardRemover) {
        self.remover = remover
    }

    func startEditing() {
        isEditing = true
    }

    func stopEditing() {
        isEditing = false
        failedCopy = nil
    }

    func remove(_ copy: OwnedCard.ID) async {
        guard !removingCopies.contains(copy) else { return }
        removingCopies.insert(copy)
        failedCopy = nil
        do {
            try await remover.remove(ownedCardIDs: [copy])
        } catch {
            failedCopy = copy
        }
        removingCopies.remove(copy)
    }
}
