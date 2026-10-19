//
//  NetworkClient.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

public protocol NetworkClient {
    typealias URLResult = (Data, HTTPURLResponse)
    func perform(_ request: URLRequest) async throws -> URLResult
}
