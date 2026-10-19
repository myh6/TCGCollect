//
//  ChatURLEndpoint.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/19.
//

import Foundation

enum ChatURLEndpoint {
    case sendMessage

    func url(baseURL: URL) -> URL {
        switch self {
        case .sendMessage:
            return baseURL.appending(path: "v1/chat")
        }
    }
}
