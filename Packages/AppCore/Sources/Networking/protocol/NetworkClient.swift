//
//  NetworkClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

public protocol NetworkClient {
    typealias URLResult = (Data, HTTPURLResponse)
    func get(from url: URL) async throws -> URLResult
    func post(_ data: Data, to url: URL) async throws -> URLResult
}
