//
//  SearchSectionViews.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import SwiftUI

/// One section's results, or why there are none.
struct SearchResults<Item: Equatable, Rows: View>: View {
    let state: SearchSectionViewModel<Item>.State
    let noResultsMessage: LocalizedStringKey
    @ViewBuilder let rows: ([Item]) -> Rows

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case let .searching(previous) where previous.isEmpty:
            ProgressView()
                .frame(maxWidth: .infinity)
        case let .searching(items), let .loaded(items):
            if items.isEmpty {
                Text(noResultsMessage)
                    .foregroundStyle(.secondary)
            } else {
                rows(items)
            }
        case .failed:
            Label("Couldn't search. Please try again.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }
}

struct SearchSectionHeader: View {
    let title: LocalizedStringKey
    let isSearching: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            // While the results of the search before stay on screen.
            if isSearching {
                ProgressView()
                    .controlSize(.mini)
            }
        }
    }
}
