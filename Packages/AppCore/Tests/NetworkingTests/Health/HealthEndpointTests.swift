//
//  HealthEndpointTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation
import Testing
@testable import Networking

struct HealthEndpointTests {

    @Test func check_getsHealthFromBaseURL() {
        let request = HealthEndpoint.check.urlRequest(baseURL: URL(string: "http://base-url.com")!)

        #expect(request.url?.absoluteString == "http://base-url.com/health")
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }

    @Test func check_preservesBaseURLPath() {
        let request = HealthEndpoint.check.urlRequest(baseURL: URL(string: "http://base-url.com/staging")!)

        #expect(request.url?.absoluteString == "http://base-url.com/staging/health")
    }
}
