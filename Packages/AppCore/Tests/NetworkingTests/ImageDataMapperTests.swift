import Testing
@testable import Networking
import TestHelpers

import Foundation

struct ImageDataMapperTests {

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: ImageDataMapper.Error.invalidData) {
            try ImageDataMapper.map(anyData(), from: httpResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        #expect(throws: ImageDataMapper.Error.invalidData) {
            try ImageDataMapper.map(Data(), from: httpResponse(statusCode: 200))
        }
    }

    @Test func map_deliversDataOn200HTTPResponseWithNonEmptyData() throws {
        let imageData = Data("image data".utf8)

        let data = try ImageDataMapper.map(imageData, from: httpResponse(statusCode: 200))

        #expect(data == imageData)
    }
}
