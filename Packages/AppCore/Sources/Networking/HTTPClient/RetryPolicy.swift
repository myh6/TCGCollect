//
//  RetryPolicy.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

public struct RetryPolicy {
    public let waits: [Duration]
    public let statusCodes: Set<Int>
    public let errorCodes: Set<URLError.Code>

    public init(waits: [Duration], statusCodes: Set<Int>, errorCodes: Set<URLError.Code>) {
        self.waits = waits
        self.statusCodes = statusCodes
        self.errorCodes = errorCodes
    }

    func retries(_ response: HTTPURLResponse) -> Bool {
        statusCodes.contains(response.statusCode)
    }

    func retries(_ error: URLError) -> Bool {
        errorCodes.contains(error.code)
    }
}
