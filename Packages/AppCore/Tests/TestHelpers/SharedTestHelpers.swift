import Foundation

public func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

public func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

public func httpResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}
