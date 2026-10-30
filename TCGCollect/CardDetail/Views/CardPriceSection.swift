//
//  CardPriceSection.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import Charts
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
            PriceHistoryView(history: PriceHistoryPresentation(points), range: viewModel.range)
        }
    }
}

struct PriceHistoryView: View {
    let history: PriceHistoryPresentation
    let range: CardPriceViewModel.Range

    var body: some View {
        if let currentPrice = history.currentPrice {
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(currentPrice)
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                    Text("Market price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                if let change = history.change {
                    changeRow(change)
                    chart(color: change.direction.color)
                }
            }
        } else {
            Text("No price history yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func changeRow(_ change: PriceHistoryPresentation.Change) -> some View {
        HStack(spacing: 6) {
            Image(systemName: change.direction.symbolName)
            Text(change.amount)
            if let percent = change.percent {
                Text("(\(percent))")
            }
            Text(range.changePeriod)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.semibold).monospacedDigit())
        .foregroundStyle(change.direction.color)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chart(color: Color) -> some View {
        if let priceRange = history.chartPriceRange {
            Chart(history.chartPoints) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Price", priceRange.lowerBound),
                    yEnd: .value("Price", point.price)
                )
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.25), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
                LineMark(x: .value("Date", point.date), y: .value("Price", point.price))
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
            }
            .chartYScale(domain: priceRange)
            .frame(height: 160)
            .accessibilityHidden(true)
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

private extension PriceHistoryPresentation.Direction {
    var color: Color {
        switch self {
        case .up: .green
        case .down: .red
        case .flat: .secondary
        }
    }

    var symbolName: String {
        switch self {
        case .up: "arrow.up.right"
        case .down: "arrow.down.right"
        case .flat: "arrow.right"
        }
    }
}
