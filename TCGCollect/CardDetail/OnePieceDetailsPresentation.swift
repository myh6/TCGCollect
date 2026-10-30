//
//  OnePieceDetailsPresentation.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import AppCore

nonisolated struct OnePieceDetailsPresentation: Equatable {
    struct Stat: Equatable {
        let label: String
        let value: String
    }

    let category: String
    let colors: [OnePieceDetails.Color]
    let colorNames: String?
    let stats: [Stat]
    let attributes: String?
    let types: String?
    let effect: String?

    init(_ details: OnePieceDetails, locale: Locale = .current) {
        category = details.category.name
        colors = details.colors
        colorNames = Self.joined(details.colors.map(\.name))
        stats = [
            (String(localized: "Cost"), details.cost),
            (String(localized: "Power"), details.power),
            (String(localized: "Counter"), details.counter),
            (String(localized: "Life"), details.life),
        ].compactMap { label, value in
            value.map { Stat(label: label, value: $0.formatted(.number.locale(locale))) }
        }
        attributes = Self.joined(details.attributes)
        types = Self.joined(details.types)
        effect = details.effect
    }

    private static func joined(_ names: [String]) -> String? {
        names.isEmpty ? nil : names.joined(separator: " / ")
    }
}

private nonisolated extension OnePieceDetails.Category {
    var name: String {
        switch self {
        case .leader: String(localized: "Leader")
        case .character: String(localized: "Character")
        case .event: String(localized: "Event")
        case .stage: String(localized: "Stage")
        case .don: String(localized: "DON!!")
        }
    }
}

private nonisolated extension OnePieceDetails.Color {
    var name: String {
        switch self {
        case .red: String(localized: "Red")
        case .green: String(localized: "Green")
        case .blue: String(localized: "Blue")
        case .purple: String(localized: "Purple")
        case .black: String(localized: "Black")
        case .yellow: String(localized: "Yellow")
        }
    }
}
