//
//  EndToEndEnvironment.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/27.
//

import Foundation

/// Where the real backend is, from environment variables, e.g.
/// `E2E_BASE_URL=http://192.168.1.115:8000 E2E_API_KEY=<DEV_API_KEY> swift test --filter NetworkingEndToEndTests`
///
/// Use the backend's DEV_API_KEY: chat then returns a canned answer in the real response shape
/// without calling Claude. Never commit a key value.
enum EndToEndEnvironment {
    private static let environment = ProcessInfo.processInfo.environment

    static let baseURL = environment["E2E_BASE_URL"].flatMap(URL.init(string:))
    static let apiKey = environment["E2E_API_KEY"]

    /// End-to-end suites only run when this is true, so CI without a backend skips them.
    static var isConfigured: Bool { baseURL != nil && apiKey != nil }
}
