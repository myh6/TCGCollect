import Testing
@testable import Networking
import TestHelpers

import Foundation

struct ChatResponseMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(makeAnswerJSON("an answer"), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(invalidJSON, from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithoutAnswer() {
        let json = Data(#"{"cards": []}"#.utf8)

        #expect(throws: ChatResponseMapper.Error.invalidData) {
            try ChatResponseMapper.map(json, from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversAnswerOn200HTTPResponseWithValidJSON() throws {
        let answer = try ChatResponseMapper.map(makeAnswerJSON("an answer"), from: httpResponse(statusCode: 200))

        #expect(answer == "an answer")
    }

    // MARK: - Helpers
    private func makeAnswerJSON(_ answer: String) -> Data {
        let json: [String: Any] = ["answer": answer, "cards": [["id": "OP01-001"]]]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
