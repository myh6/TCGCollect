//
//  CatalogEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation

enum CatalogEndpoint {
    case games

    func urlRequest(baseURL: URL) -> URLRequest {
        switch self {
        case .games:
            URLRequest(url: baseURL.appending(path: "v1/catalog/games"))
        }
    }
}
