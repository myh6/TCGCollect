//
//  Money+Formatting.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import AppCore

extension Money {
    nonisolated func formatted(locale: Locale = .current) -> String {
        amount.formatted(.currency(code: currencyCode).locale(locale))
    }
}
