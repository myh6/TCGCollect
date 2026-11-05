//
//  ChangeObserverStub.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import AppCore

final class ChangeObserverStub: OwnedCardChangeObserver {
    private(set) var listenCount = 0
    private let (stream, continuation) = AsyncStream.makeStream(of: Void.self)

    func changes() -> AsyncStream<Void> {
        listenCount += 1
        return stream
    }

    func announceChange() {
        continuation.yield()
    }

    func finish() {
        continuation.finish()
    }
}
