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
        // SwiftData only logs errors and recovers when the folder is missing, so create it first.
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let configuration = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: ManagedOwnedCard.self, configurations: configuration)
        self.init(modelContainer: container)
    }

    public func retrieveAll() throws -> [OwnedCard] {
        let descriptor = FetchDescriptor<ManagedOwnedCard>(sortBy: [SortDescriptor(\.position)])
        return try modelContext.fetch(descriptor).map(\.ownedCard)
    }

    public func insert(_ ownedCard: OwnedCard) throws {
        let existing = try managedOwnedCard(withID: ownedCard.id)
        // A replaced card keeps its place, so editing it doesn't move it in the collection.
        let position = try existing?.position ?? nextPosition()
        if let existing {
            modelContext.delete(existing)
        }
        modelContext.insert(ManagedOwnedCard(ownedCard, position: position))
        try modelContext.save()
    }

    public func delete(ownedCardID: OwnedCard.ID) throws {
        // Deletes straight from the store file, so there's nothing left to save.
        try modelContext.delete(model: ManagedOwnedCard.self, where: #Predicate { $0.ownedCardID == ownedCardID })
    }

    private func managedOwnedCard(withID id: OwnedCard.ID) throws -> ManagedOwnedCard? {
        var descriptor = FetchDescriptor<ManagedOwnedCard>(predicate: #Predicate { $0.ownedCardID == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func nextPosition() throws -> Int {
        var descriptor = FetchDescriptor<ManagedOwnedCard>(sortBy: [SortDescriptor(\.position, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = try modelContext.fetch(descriptor).first
        return (last?.position ?? -1) + 1
    }
}
