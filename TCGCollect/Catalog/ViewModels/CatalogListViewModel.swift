//
//  CatalogListViewModel.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Observation

@MainActor
@Observable
final class CatalogListViewModel<Item: Equatable> {
    private(set) var items = LoadingState<[Item]>.idle

    private let loadItems: () async throws -> [Item]

    init(load: @escaping () async throws -> [Item]) {
        self.loadItems = load
    }

    func load() async {
        guard items == .idle || items == .failed else { return }
        items = .loading
        do {
            items = .loaded(try await loadItems())
        } catch {
            items = .failed
        }
    }
}
