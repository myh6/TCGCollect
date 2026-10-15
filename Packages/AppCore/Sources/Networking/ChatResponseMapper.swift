//
//  ChatResponseMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/15.
//

import Foundation

enum ChatResponseMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> String {
        guard response.statusCode == 200,
              let message = String(data: data, encoding: .utf8) else {
            throw Error.invalidData
        }
        return message
    }
}
