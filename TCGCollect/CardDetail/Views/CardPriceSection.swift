//
//  CardPriceSection.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import AppCore

struct CardPriceSection: View {
    let viewModel: CardPriceViewModel

    var body: some View {
        VStack(spacing: 16) {
            rangePicker
            content
                .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: Binding(get: { viewModel.range }, set: { range in
            Task { await viewModel.select(range) }
        })) {
            ForEach(CardPriceViewModel.Range.allCases, id: \.self) { range in
                Text(range.shortName).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.history {
        case .idle, .loading:
            ProgressView()
        case .failed:
            VStack(spacing: 12) {
                Text("Couldn't load prices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
        case .loaded(let points):
            PriceHistoryView(history: PriceHistoryPresentation(points), label: "Market price", changePeriod: viewModel.range.changePeriod)
        }
    }
}

private extension CardPriceViewModel.Range {
    var shortName: LocalizedStringKey {
        switch self {
        case .month: "1M"
        case .threeMonths: "3M"
        case .all: "All"
        }
    }

    var changePeriod: LocalizedStringKey {
        switch self {
        case .month: "past month"
        case .threeMonths: "past 3 months"
        case .all: "all time"
        }
    }
}
