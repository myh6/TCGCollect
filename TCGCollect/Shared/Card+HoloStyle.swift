//
//  Card+HoloStyle.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/29.
//

import Foundation
import AppCore
import HoloCard

extension Card {
    nonisolated var holoStyle: HoloStyle {
        isFoil ? .rainbow : .plain
    }

    private nonisolated var isFoil: Bool {
        printing?.caseInsensitiveCompare("Foil") == .orderedSame
    }
}
