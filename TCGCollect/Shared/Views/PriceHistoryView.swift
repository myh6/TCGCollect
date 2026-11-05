//
//  PriceHistoryView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import SwiftUI
import Charts
import AppCore

struct PriceHistoryView: View {
    let history: PriceHistoryPresentation
    let label: LocalizedStringKey
    let changePeriod: LocalizedStringKey

    var body: some View {
        if let currentPrice = history.currentPrice {
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(currentPrice)
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                    Text(label)
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
            Text(changePeriod)
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

#if DEBUG
private func previewHistory(_ amounts: [Decimal]) -> PriceHistoryPresentation {
    PriceHistoryPresentation(prices: amounts.enumerated().map { index, amount in
        (date: .now.addingTimeInterval(TimeInterval(index - amounts.count + 1) * 86_400), price: Money(amount: amount, currencyCode: "USD"))
    })
}

#Preview("Rising") {
    PriceHistoryView(history: previewHistory([4.43, 4.60, 4.52, 4.71, 4.85]), label: "Market price", changePeriod: "past month")
        .padding()
}

#Preview("Falling") {
    PriceHistoryView(history: previewHistory([129.80, 126.10, 127.40, 121.00, 118.40]), label: "Collection value", changePeriod: "past week")
        .padding()
}

#Preview("Flat") {
    PriceHistoryView(history: previewHistory([2.00, 2.10, 2.00]), label: "Market price", changePeriod: "past 3 months")
        .padding()
}

#Preview("One price") {
    PriceHistoryView(history: previewHistory([4.85]), label: "Market price", changePeriod: "past month")
        .padding()
}

#Preview("No history") {
    PriceHistoryView(history: previewHistory([]), label: "Market price", changePeriod: "past month")
        .padding()
}
#endif
