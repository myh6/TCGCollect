import Foundation

public func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

public func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

public func anyData() -> Data {
    Data("any data".utf8)
}

public func anyHTTPURLResponse() -> HTTPURLResponse {
    httpResponse(statusCode: 200)
}

public func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}

public func httpResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}
