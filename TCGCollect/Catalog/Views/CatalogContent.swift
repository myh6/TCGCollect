//
//  CatalogContent.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import SwiftUI

struct CatalogContent<Value: Equatable, Loaded: View>: View {
    let state: LoadingState<Value>
    let failureTitle: LocalizedStringKey
    let retry: () async -> Void
    @ViewBuilder let loaded: (Value) -> Loaded

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
        case let .loaded(value):
            loaded(value)
        case .failed:
            ContentUnavailableView {
                Label(failureTitle, systemImage: "exclamationmark.triangle")
            } description: {
                Text("Please try again later.")
            } actions: {
                Button("Try Again") {
                    Task { await retry() }
                }
            }
        }
    }
}
