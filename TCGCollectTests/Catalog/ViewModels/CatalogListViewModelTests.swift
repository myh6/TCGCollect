//
//  CatalogListViewModelTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/11/06.
//

import Foundation
import Testing
@testable import TCGCollect

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CatalogListViewModelTests {

    @Test func init_doesNotLoad() {
        let (sut, loader) = makeSUT()

        #expect(sut.items == .idle)
        #expect(loader.loadCount == 0)
    }

    @Test func load_isLoadingWhileWaitingForItems() async {
        let (sut, loader) = makeSUT()

        let loading = await startLoading(sut, loader: loader)
        #expect(sut.items == .loading)

        loader.complete(with: .success([]))
        await loading.value
    }

    @Test func load_deliversItemsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .success([1, 2]))

        #expect(sut.items == .loaded([1, 2]))
    }

    @Test func load_failsOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        await load(sut, loader: loader, completingWith: .failure(anyError()))

        #expect(sut.items == .failed)
    }

    @Test func load_ignoresLoadWhileLoading() async {
        let (sut, loader) = makeSUT()
        let firstLoading = await startLoading(sut, loader: loader)
        loader.setCompletionForNewCalls(to: .success([]))

        await sut.load()
        #expect(loader.loadCount == 1)

        loader.complete(with: .success([]))
        await firstLoading.value
    }

    @Test func load_doesNotReloadLoadedItems() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .success([1]))
        loader.setCompletionForNewCalls(to: .success([2]))

        await sut.load()

        #expect(loader.loadCount == 1)
        #expect(sut.items == .loaded([1]))
    }

    @Test func load_retriesAfterFailure() async {
        let (sut, loader) = makeSUT()
        await load(sut, loader: loader, completingWith: .failure(anyError()))
        loader.setCompletionForNewCalls(to: .success([1]))

        await sut.load()

        #expect(loader.loadCount == 2)
        #expect(sut.items == .loaded([1]))
    }

    // MARK: - Helpers
    private func makeSUT() -> (sut: CatalogListViewModel<Int>, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CatalogListViewModel(load: loader.load)
        return (sut, loader)
    }

    private func anyError() -> Error {
        NSError(domain: "any error", code: 0)
    }

    private func startLoading(
        _ sut: CatalogListViewModel<Int>, loader: LoaderSpy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async -> Task<Void, Never> {
        let loading = Task { await sut.load() }
        await loader.waitForCall(at: 0, sourceLocation: sourceLocation)
        return loading
    }

    private func load(
        _ sut: CatalogListViewModel<Int>, loader: LoaderSpy, completingWith result: Result<[Int], Error>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        let loading = await startLoading(sut, loader: loader, sourceLocation: sourceLocation)
        loader.complete(with: result)
        await loading.value
    }

    private final class LoaderSpy: HeldCalls<Void, [Int]> {
        var loadCount: Int { inputs.count }

        init() {
            super.init(callName: "load")
        }

        func load() async throws -> [Int] {
            try await call(with: ())
        }
    }
}
