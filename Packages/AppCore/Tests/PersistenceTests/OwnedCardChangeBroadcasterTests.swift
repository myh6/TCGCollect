//
//  OwnedCardChangeBroadcasterTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/11/03.
//

import Foundation
import Testing
@testable import Persistence

@Suite(.timeLimit(.minutes(1)))
struct OwnedCardChangeBroadcasterTests {

    @Test func changes_deliversAnnouncementToEveryListener() async {
        let sut = OwnedCardChangeBroadcaster()
        var first = sut.changes().makeAsyncIterator()
        var second = sut.changes().makeAsyncIterator()

        sut.announce()

        #expect(await first.next() != nil)
        #expect(await second.next() != nil)
    }

    @Test func changes_deliversNothingAnnouncedBeforeListening() async {
        var sut: OwnedCardChangeBroadcaster? = OwnedCardChangeBroadcaster()
        sut?.announce()
        var changes = sut?.changes().makeAsyncIterator()

        sut = nil

        #expect(await changes?.next() == nil)
    }

    @Test func changes_endWhenBroadcasterIsGone() async {
        var sut: OwnedCardChangeBroadcaster? = OwnedCardChangeBroadcaster()
        var changes = sut?.changes().makeAsyncIterator()

        sut = nil

        #expect(await changes?.next() == nil)
    }

    @Test func changes_collapseAnnouncementsWaitingForASlowListener() async {
        var sut: OwnedCardChangeBroadcaster? = OwnedCardChangeBroadcaster()
        let changes = sut?.changes()

        sut?.announce()
        sut?.announce()
        sut?.announce()
        sut = nil

        var received = 0
        for await _ in changes ?? AsyncStream { $0.finish() } {
            received += 1
        }
        #expect(received == 1)
    }

    @Test func changes_stopsKeepingListenerOnceItsStreamIsGone() {
        let sut = OwnedCardChangeBroadcaster()

        _ = sut.changes()

        #expect(sut.listenerCount == 0)
    }

    @Test func changes_keepsListenerWhileItsStreamIsInUse() {
        let sut = OwnedCardChangeBroadcaster()

        let changes = sut.changes()

        #expect(sut.listenerCount == 1)
        withExtendedLifetime(changes) {}
    }
}
