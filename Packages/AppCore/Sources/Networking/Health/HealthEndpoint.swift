//
//  HealthEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

enum HealthEndpoint {
    case check

    func urlRequest(baseURL: URL) -> URLRequest {
        switch self {
        case .check:
            var request = URLRequest(url: baseURL.appending(path: "health"))
            request.httpMethod = "GET"
            return request
        }
    }
}
