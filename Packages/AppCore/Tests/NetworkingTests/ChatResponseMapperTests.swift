import Testing
@testable import Networking

import Foundation

struct ChatResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(Data("a message".utf8), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataErrorOnNonHTTPResponse() {
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(Data("a message".utf8), from: nonHTTPResponse)
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithInvalidData() {
        let invalidUTF8 = Data([0xFF])

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(invalidUTF8, from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversMessageOn200HTTPResponseWithValidData() throws {
        let message = try ChatResponseMapper.map(Data("a reply".utf8), from: httpResponse(statusCode: 200))

        #expect(message == "a reply")
    }

    // MARK: - Helpers
    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
