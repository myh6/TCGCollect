//
//  ImageDataMapper.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Foundation

enum ImageDataMapper {
    enum Error: Swift.Error, Equatable {
        case invalidData
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard response.statusCode == 200, !data.isEmpty else {
            throw Error.invalidData
        }
        return data
    }
}
