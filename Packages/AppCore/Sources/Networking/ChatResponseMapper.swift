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

    private struct AskResponse: Decodable {
        let answer: String
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> String {
        guard response.statusCode == 200,
              let askResponse = try? JSONDecoder().decode(AskResponse.self, from: data) else {
            throw Error.invalidData
        }
        return askResponse.answer
    }
}
