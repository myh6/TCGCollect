//
//  BackendConfiguration.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation

/// The backend's base URL and API key, read from the values Secrets.xcconfig puts into Info.plist.
nonisolated struct BackendConfiguration: Equatable {
    enum Error: Swift.Error, Equatable {
        case missingValue(key: String)
        case invalidBaseURL(String)
    }

    static let baseURLKey = "BackendBaseURL"
    static let apiKeyKey = "BackendAPIKey"

    let baseURL: URL
    let apiKey: String

    init(infoDictionary: [String: Any]) throws {
        let baseURLString = try Self.value(for: Self.baseURLKey, in: infoDictionary)
        guard let url = URL(string: baseURLString), url.scheme != nil, url.host() != nil else {
            throw Error.invalidBaseURL(baseURLString)
        }
        baseURL = url
        apiKey = try Self.value(for: Self.apiKeyKey, in: infoDictionary)
    }

    /// A variable missing from Secrets.xcconfig expands to "" in Info.plist, so empty counts as missing.
    private static func value(for key: String, in infoDictionary: [String: Any]) throws -> String {
        guard let value = infoDictionary[key] as? String, !value.isEmpty else {
            throw Error.missingValue(key: key)
        }
        return value
    }
}
