//
//  SwiftDataOwnedCardStore.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation
import SwiftData
import Domain

/// Keeps owned cards in a SwiftData store file. A model actor, so its context is only used on the actor's own queue.
@ModelActor
public actor SwiftDataOwnedCardStore: OwnedCardStore {
    public init(storeURL: URL) throws {
        try self.init(storeURL: storeURL, allowsSave: true)
    }

    /// With `allowsSave` false, every save fails, so tests can check what a failed save leaves behind.
    init(storeURL: URL, allowsSave: Bool) throws {
        // SwiftData only logs errors and recovers when the folder is missing, so create it first.
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let configuration = ModelConfiguration(url: storeURL, allowsSave: allowsSave)
        let container = try ModelContainer(for: ManagedOwnedCard.self, configurations: configuration)
        self.init(modelContainer: container)
    }

    public func retrieveAll() throws -> [OwnedCard] {
        let descriptor = FetchDescriptor<ManagedOwnedCard>(sortBy: [SortDescriptor(\.position)])
        return try modelContext.fetch(descriptor).map(\.ownedCard)
    }

    public func insert(_ ownedCards: [OwnedCard]) throws {
        // A context just for this batch: if saving fails, it's thrown away with the unsaved changes.
        // Rolling back the shared context doesn't drop them, so its fetches would still show the failed batch.
        let context = ModelContext(modelContainer)
        var nextPosition = try nextPosition(in: context)
        for ownedCard in ownedCards {
            let position: Int
            // Also finds one inserted earlier in this batch, since fetches include unsaved changes.
            if let existing = try managedOwnedCard(withID: ownedCard.id, in: context) {
                // A replaced card keeps its place, so editing it doesn't move it in the collection.
                position = existing.position
                context.delete(existing)
            } else {
                position = nextPosition
                nextPosition += 1
            }
            context.insert(ManagedOwnedCard(ownedCard, position: position))
        }
        // One save for the whole batch, so it's stored all at once or not at all.
        try context.save()
    }

    public func delete(ownedCardID: OwnedCard.ID) throws {
        // Deletes straight from the store file, so there's nothing left to save.
        try modelContext.delete(model: ManagedOwnedCard.self, where: #Predicate { $0.ownedCardID == ownedCardID })
    }

    private func managedOwnedCard(withID id: OwnedCard.ID, in context: ModelContext) throws -> ManagedOwnedCard? {
        var descriptor = FetchDescriptor<ManagedOwnedCard>(predicate: #Predicate { $0.ownedCardID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func nextPosition(in context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<ManagedOwnedCard>(sortBy: [SortDescriptor(\.position, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = try context.fetch(descriptor).first
        return (last?.position ?? -1) + 1
    }
}
