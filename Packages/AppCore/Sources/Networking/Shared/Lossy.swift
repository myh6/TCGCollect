//
//  Lossy.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

/// Decodes a value without throwing, so one malformed item doesn't fail a whole list.
struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}
