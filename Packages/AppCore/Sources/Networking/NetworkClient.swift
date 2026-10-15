//
//  NetworkClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

public protocol NetworkClient {
    typealias URLResult = (Data, URLResponse)
    func get(from url: URL) async throws -> URLResult
}
