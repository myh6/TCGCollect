//
//  RemoteLoader.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public struct RemoteLoader<Input, Resource> {
    public typealias MakeRequest = (Input) throws -> URLRequest
    public typealias Map = (Data, HTTPURLResponse) throws -> Resource

    private let client: NetworkClient
    private let makeRequest: MakeRequest
    private let map: Map

    public init(client: NetworkClient, makeRequest: @escaping MakeRequest, map: @escaping Map) {
        self.client = client
        self.makeRequest = makeRequest
        self.map = map
    }

    public func load(_ input: Input) async throws -> Resource {
        let (data, response) = try await client.perform(makeRequest(input))
        return try map(data, response)
    }
}
