//
//  OwnedCardChangeBroadcaster.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import os

final class OwnedCardChangeBroadcaster: Sendable {
    private let listeners = OSAllocatedUnfairLock(initialState: [UUID: AsyncStream<Void>.Continuation]())

    var listenerCount: Int {
        listeners.withLock { $0.count }
    }

    deinit {
        for listener in currentListeners {
            listener.finish()
        }
    }

    func changes() -> AsyncStream<Void> {
        let (stream, listener) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        listeners.withLock { $0[id] = listener }
        listener.onTermination = { [listeners] _ in
            listeners.withLock { $0[id] = nil }
        }
        return stream
    }

    func announce() {
        for listener in currentListeners {
            listener.yield()
        }
    }

    private var currentListeners: [AsyncStream<Void>.Continuation] {
        listeners.withLock { Array($0.values) }
    }
}
