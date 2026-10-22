//
//  ChatLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/22.
//

import Domain

public protocol ChatLoader {
    func load(question: String) async throws -> ChatAnswer
}
