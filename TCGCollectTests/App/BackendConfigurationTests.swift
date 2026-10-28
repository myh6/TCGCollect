//
//  BackendConfigurationTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/21.
//

import Foundation
import Testing
@testable import TCGCollect

struct BackendConfigurationTests {

    @Test func init_deliversBaseURLAndAPIKeyFromInfoDictionary() throws {
        let sut = try BackendConfiguration(infoDictionary: makeInfo())

        #expect(sut.baseURL == URL(string: "http://base-url.com")!)
        #expect(sut.apiKey == "an api key")
    }

    @Test(arguments: [BackendConfiguration.baseURLKey, BackendConfiguration.apiKeyKey])
    func init_throwsMissingValueWhenKeyIsAbsent(key: String) {
        var info = makeInfo()
        info[key] = nil

        #expect(throws: BackendConfiguration.Error.missingValue(key: key)) {
            try BackendConfiguration(infoDictionary: info)
        }
    }

    // A variable missing from Secrets.xcconfig reaches Info.plist as an empty string.
    @Test(arguments: [BackendConfiguration.baseURLKey, BackendConfiguration.apiKeyKey])
    func init_throwsMissingValueWhenValueIsEmpty(key: String) {
        var info = makeInfo()
        info[key] = ""

        #expect(throws: BackendConfiguration.Error.missingValue(key: key)) {
            try BackendConfiguration(infoDictionary: info)
        }
    }

    @Test(arguments: ["not a url", "192.168.1.113:8000", "http://"])
    func init_throwsInvalidBaseURLOnMalformedURL(baseURL: String) {
        let info = makeInfo(baseURL: baseURL)

        #expect(throws: BackendConfiguration.Error.invalidBaseURL(baseURL)) {
            try BackendConfiguration(infoDictionary: info)
        }
    }

    // MARK: - Helpers
    private func makeInfo(baseURL: String = "http://base-url.com", apiKey: String = "an api key") -> [String: Any] {
        [BackendConfiguration.baseURLKey: baseURL, BackendConfiguration.apiKeyKey: apiKey]
    }
}
