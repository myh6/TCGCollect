//
//  MoneyFormattingTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
import AppCore
@testable import TCGCollect

struct MoneyFormattingTests {

    @Test(arguments: [
        ("9.99", "USD", "en_US", "$9.99"),
        ("1234.5", "USD", "en_US", "$1,234.50"),
        ("9.99", "EUR", "en_US", "€9.99"),
        ("1234.5", "USD", "de_DE", "1.234,50\u{00A0}$"),
    ])
    func formatted_showsAmountInItsCurrencyForLocale(amount: String, currencyCode: String, locale: String, expected: String) {
        let money = Money(amount: Decimal(string: amount)!, currencyCode: currencyCode)

        #expect(money.formatted(locale: Locale(identifier: locale)) == expected)
    }
}
