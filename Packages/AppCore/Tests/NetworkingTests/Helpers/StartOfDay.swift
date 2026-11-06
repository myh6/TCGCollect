//
//  StartOfDay.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

func startOfDay(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
}
