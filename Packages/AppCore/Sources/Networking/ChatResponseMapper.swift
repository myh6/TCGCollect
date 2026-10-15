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

    static func map(_ data: Data, from response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let message = String(data: data, encoding: .utf8) else {
            throw Error.invalidData
        }
        return message
    }
}
