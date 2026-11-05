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

    public func countCopies(of cardID: Card.ID) throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<ManagedOwnedCard>(predicate: #Predicate { $0.cardID == cardID }))
    }

    public func insert(_ ownedCards: [OwnedCard]) throws {
        // A context just for this batch: if saving fails, it's thrown away with the unsaved changes.
        // Rolling back the shared context doesn't drop them, so its fetches would still show the failed batch.
        let context = ModelContext(modelContainer)
        var nextPosition = try nextPosition(in: context)
        for ownedCard in ownedCards {
            if let stored = try managedOwnedCard(withID: ownedCard.id, in: context) {
                stored.update(from: ownedCard)
            } else {
                context.insert(ManagedOwnedCard(ownedCard, position: nextPosition))
                nextPosition += 1
            }
        }
        try context.save()
    }

    public func delete(ownedCardIDs: [OwnedCard.ID]) throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ManagedOwnedCard>(predicate: #Predicate { ownedCardIDs.contains($0.ownedCardID) })
        for stored in try context.fetch(descriptor) {
            context.delete(stored)
        }
        try context.save()
    }

    public func deleteNewestCopy(of cardID: Card.ID) throws {
        let context = ModelContext(modelContainer)
        guard let newest = try managedOwnedCard(matching: #Predicate { $0.cardID == cardID }, sortBy: newestFirst, in: context) else { return }
        context.delete(newest)
        try context.save()
    }

    private let newestFirst = [SortDescriptor(\ManagedOwnedCard.position, order: .reverse)]

    private func managedOwnedCard(withID id: OwnedCard.ID, in context: ModelContext) throws -> ManagedOwnedCard? {
        try managedOwnedCard(matching: #Predicate { $0.ownedCardID == id }, in: context)
    }

    private func managedOwnedCard(
        matching predicate: Predicate<ManagedOwnedCard>? = nil,
        sortBy: [SortDescriptor<ManagedOwnedCard>] = [],
        in context: ModelContext
    ) throws -> ManagedOwnedCard? {
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func nextPosition(in context: ModelContext) throws -> Int {
        let last = try managedOwnedCard(sortBy: newestFirst, in: context)
        return (last?.position ?? -1) + 1
    }
}
