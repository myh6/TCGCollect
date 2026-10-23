//
//  Item.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
