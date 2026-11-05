//
//  RemoteDay.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

enum RemoteDay {
    static func startOfDay(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }
}
