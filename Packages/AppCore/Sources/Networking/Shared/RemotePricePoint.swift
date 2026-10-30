//
//  RemotePricePoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Domain

enum RemotePricePoint {
    static func make(cardID: Int, amount: String?, currency: String?, fetchedAt: String?) -> PricePoint? {
        guard let amount, let currency, let fetchedAt,
              // A string, so it converts to Decimal exactly; a JSON number would go through Double first.
              let decimal = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")),
              let date = date(from: fetchedAt) else { return nil }
        return PricePoint(cardID: cardID, date: date, price: Money(amount: decimal, currencyCode: currency))
    }

    private static func date(from text: String) -> Date? {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFractionalSeconds.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
