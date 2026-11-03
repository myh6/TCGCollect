//
//  CollectionValueHistory.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation

public struct CollectionValueHistory: Hashable, Sendable {
    public let currentTotal: Money?
    public let points: [CollectionValuePoint]

    public init(currentTotal: Money?, points: [CollectionValuePoint]) {
        self.currentTotal = currentTotal
        self.points = points
    }
}

public struct CollectionValuePoint: Hashable, Sendable {
    public let date: Date
    public let value: Money

    public init(date: Date, value: Money) {
        self.date = date
        self.value = value
    }
}
