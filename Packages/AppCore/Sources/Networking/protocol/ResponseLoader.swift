//
//  ResponseLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

public protocol ResponseLoader {
    func load(from input: String) async throws -> String
}
