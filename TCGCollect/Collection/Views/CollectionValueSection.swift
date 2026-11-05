//
//  CollectionValueSection.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import SwiftUI
import AppCore

struct CollectionValueSection: View {
    let viewModel: CollectionValueViewModel
    let ownedCards: [OwnedCard]

    var body: some View {
        VStack(spacing: 16) {
            rangePicker
            content
                .frame(maxWidth: .infinity, minHeight: 120)
        }
        .task(id: ownedCards) { await viewModel.load(ownedCards) }
    }

    private var rangePicker: some View {
        Picker("Range", selection: Binding(get: { viewModel.range }, set: { range in
            Task { await viewModel.select(range) }
        })) {
            ForEach(CollectionValueViewModel.Range.allCases, id: \.self) { range in
                Text(range.shortName).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.valueHistory {
        case .idle, .loading:
            ProgressView()
        case .failed:
            VStack(spacing: 12) {
                Text("Couldn't load your collection's value.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    Task { await viewModel.load(ownedCards) }
                }
                .buttonStyle(.bordered)
            }
        case .loaded(let history):
            PriceHistoryView(history: PriceHistoryPresentation(history), label: "Collection value", changePeriod: viewModel.range.changePeriod)
                .opacity(viewModel.isReloading ? 0.4 : 1)
                .overlay {
                    if viewModel.isReloading {
                        ProgressView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.isReloading)
        }
    }
}

private extension CollectionValueViewModel.Range {
    var shortName: LocalizedStringKey {
        switch self {
        case .week: "1W"
        case .month: "1M"
        case .threeMonths: "3M"
        }
    }

    var changePeriod: LocalizedStringKey {
        switch self {
        case .week: "past week"
        case .month: "past month"
        case .threeMonths: "past 3 months"
        }
    }
}
