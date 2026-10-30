//
//  ExponentialWaitsTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Testing
import Networking

struct ExponentialWaitsTests {

    @Test func exponential_doublesEachWaitUntilTheTotal() {
        #expect([Duration].exponential(from: .seconds(1), upTo: .seconds(7)) == seconds([1, 2, 4]))
    }

    @Test func exponential_shortensTheLastWaitToEndAtTheTotal() {
        #expect([Duration].exponential(from: .seconds(1), upTo: .seconds(10)) == seconds([1, 2, 4, 3]))
        #expect([Duration].exponential(from: .seconds(1), upTo: .seconds(60)) == seconds([1, 2, 4, 8, 16, 29]))
    }

    @Test func exponential_waitsOnlyTheTotalWhenTheFirstWaitIsLonger() {
        #expect([Duration].exponential(from: .seconds(10), upTo: .seconds(5)) == seconds([5]))
    }

    @Test(arguments: [(Duration.seconds(1), Duration.zero), (.zero, .seconds(60))])
    func exponential_hasNoWaitsWithoutTimeToWait(first: Duration, total: Duration) {
        #expect([Duration].exponential(from: first, upTo: total).isEmpty)
    }

    // MARK: - Helpers
    private func seconds(_ values: [Int]) -> [Duration] {
        values.map { .seconds($0) }
    }
}
