//
//  RemoteLoader+ChatLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Domain

extension RemoteLoader: ChatLoader where Input == String, Resource == ChatAnswer {
    public func load(question: String) async throws -> ChatAnswer {
        try await load(question)
    }
}
