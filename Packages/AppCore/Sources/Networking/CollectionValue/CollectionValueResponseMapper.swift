//
//  CollectionValueResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Domain

enum CollectionValueResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    private static let currencyCode = "USD"

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> CollectionValueHistory {
        guard response.statusCode == 200,
              let body = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            throw Error.invalidData
        }
        return CollectionValueHistory(
            currentTotal: body.current_total.flatMap(dollars),
            points: body.history.compactMap(\.value?.valuePoint)
        )
    }

    private static func dollars(_ amount: String) -> Money? {
        Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")).map { Money(amount: $0, currencyCode: currencyCode) }
    }

    private static func startOfDay(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }

    private struct ResponseBody: Decodable {
        let current_total: String?
        let history: [Lossy<Point>]
    }

    private struct Point: Decodable {
        let date: String
        let total_value: String

        var valuePoint: CollectionValuePoint? {
            guard let day = startOfDay(date), let value = dollars(total_value) else { return nil }
            return CollectionValuePoint(date: day, value: value)
        }
    }
}
