//
//  TCGCollectApp.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/12.
//

import SwiftUI
import AppCore
import os

@main
struct TCGCollectApp: App {
    // Owned here, not by ChatView, so a request and its answer survive switching tabs.
    @State private var chatViewModel = Self.makeChatViewModel()
    // One for the whole app, so every screen shares the images already in memory.
    @State private var imageLoader = Self.makeImageLoader()
    // Only one for the whole app: Core Data can crash if several new store files are set up at the same moment.
    @State private var ownedCardCollection: OwnedCardCollection?
    // Owned here so what was added stays marked as added after switching tabs.
    @State private var addToCollectionViewModel: AddToCollectionViewModel?
    // Owned here so the cards stay on screen while the tab reloads them.
    @State private var collectionViewModel: CollectionViewModel?
    // Owned here so the results stay on screen after switching tabs.
    @State private var ownedCardsSearch: SearchSectionViewModel<OwnedCardGroup>?
    @State private var onlineCardsSearch = Self.makeOnlineCardsSearch()
    private let cardDetailsLoader = Self.makeCardDetailsLoader()
    private let cardPriceHistoryLoader = Self.makeCardPriceHistoryLoader()

    init() {
        // Both from the same collection, so the app never opens the store twice.
        let collection = Self.makeOwnedCardCollection()
        _ownedCardCollection = State(initialValue: collection)
        _addToCollectionViewModel = State(initialValue: collection.map { AddToCollectionViewModel(saver: $0) })
        _collectionViewModel = State(initialValue: collection.map { CollectionViewModel(loader: $0) })
        _ownedCardsSearch = State(initialValue: collection.map {
            CardSearchUIComposer.makeOwnedCardsSection(searching: OwnedCardComposer.makeOwnedCardSearcher(searching: $0))
        })
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.text.bubble.right") {
                    NavigationStack {
                        if let chatViewModel {
                            ChatView(viewModel: chatViewModel, addToCollection: addToCollectionViewModel)
                                .navigationDestination(for: Card.self, destination: cardDetail)
                        } else {
                            ChatUnavailableView()
                        }
                    }
                }
                Tab("Collection", systemImage: "rectangle.stack") {
                    NavigationStack {
                        if let collectionViewModel {
                            CollectionView(viewModel: collectionViewModel)
                                .navigationDestination(for: Card.self, destination: cardDetail)
                        } else {
                            CollectionUnavailableView()
                        }
                    }
                }
                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    NavigationStack {
                        CardSearchView(
                            ownedCards: ownedCardsSearch,
                            onlineCards: onlineCardsSearch,
                            makeAddToCollection: makeSearchAddToCollection
                        )
                        .navigationDestination(for: Card.self, destination: cardDetail)
                    }
                }
            }
            .environment(\.imageLoader, imageLoader)
            #if DEBUG
            .task {
                if SampleCards.isOn, let ownedCardCollection {
                    await SampleCards.addMissing(to: ownedCardCollection)
                }
            }
            #endif
        }
    }

    private func cardDetail(for card: Card) -> some View {
        CardDetailScreen(
            card: card,
            loader: cardDetailsLoader,
            priceHistoryLoader: cardPriceHistoryLoader,
            ownership: ownedCardCollection.map { CardDetailUIComposer.makeOwnership(of: card.id, in: $0) }
        )
    }

    private var makeSearchAddToCollection: (() -> AddToCollectionViewModel)? {
        guard let ownedCardCollection, let ownedCardsSearch else { return nil }
        return { CardSearchUIComposer.makeAddToCollection(saving: ownedCardCollection, refreshing: ownedCardsSearch) }
    }

    /// nil when the backend isn't configured, e.g. in Release builds for now.
    private static func makeChatViewModel() -> ChatViewModel? {
        do {
            let configuration = try BackendConfiguration(infoDictionary: Bundle.main.infoDictionary ?? [:])
            let loader = ChatComposer.makeRemoteChatLoader(baseURL: configuration.baseURL, apiKey: configuration.apiKey)
            return ChatViewModel(loader: loader)
        } catch {
            Logger(subsystem: "TCGCollect", category: "Chat").error("Chat unavailable: \(String(describing: error))")
            return nil
        }
    }

    /// nil when the backend isn't configured, so only the cards the user owns are searched.
    private static func makeOnlineCardsSearch() -> SearchSectionViewModel<CardSearchResult>? {
        do {
            let configuration = try BackendConfiguration(infoDictionary: Bundle.main.infoDictionary ?? [:])
            let searcher = CardSearchComposer.makeRemoteCardSearcher(baseURL: configuration.baseURL, apiKey: configuration.apiKey)
            return CardSearchUIComposer.makeOnlineCardsSection(searching: searcher)
        } catch {
            Logger(subsystem: "TCGCollect", category: "Search").error("Online search unavailable: \(String(describing: error))")
            return nil
        }
    }

    /// Without a backend the page still shows the card, just without its details.
    private static func makeCardDetailsLoader() -> CardDetailsLoader {
        #if DEBUG
        if SampleCards.isOn { return SampleCardDetailsLoader() }
        #endif
        do {
            let configuration = try BackendConfiguration(infoDictionary: Bundle.main.infoDictionary ?? [:])
            return CardDetailsComposer.makeRemoteCardDetailsLoader(baseURL: configuration.baseURL, apiKey: configuration.apiKey)
        } catch {
            Logger(subsystem: "TCGCollect", category: "CardDetail").error("Card details unavailable: \(String(describing: error))")
            return NoCardDetailsLoader()
        }
    }

    /// Without a backend the page shows no price history.
    private static func makeCardPriceHistoryLoader() -> CardPriceHistoryLoader {
        do {
            let configuration = try BackendConfiguration(infoDictionary: Bundle.main.infoDictionary ?? [:])
            return PriceHistoryComposer.makeRemoteCardPriceHistoryLoader(baseURL: configuration.baseURL, apiKey: configuration.apiKey)
        } catch {
            Logger(subsystem: "TCGCollect", category: "CardDetail").error("Price history unavailable: \(String(describing: error))")
            return NoCardPriceHistoryLoader()
        }
    }

    /// Memory first, then the disk cache, then the network; downloads are saved to disk for next time.
    private static func makeImageLoader() -> ImageLoader {
        let cacheDirectory = URL.cachesDirectory.appending(path: "CardImages", directoryHint: .isDirectory)
        let dataLoader = CachedImageComposer.makeImageDataLoader(
            remote: ImageComposer.makeRemoteImageDataLoader(),
            cacheDirectory: cacheDirectory
        )
        return ImageLoader(dataLoader: dataLoader, memoryCache: ImageMemoryCache())
    }

    /// Kept in Application Support, not Caches, since the system may clear Caches but a collection must never disappear.
    /// nil when the store can't be opened, so the rest of the app still works.
    private static func makeOwnedCardCollection() -> OwnedCardCollection? {
        let storeURL = URL.applicationSupportDirectory.appending(path: "Collection/OwnedCards.store")
        do {
            return try OwnedCardComposer.makeLocalOwnedCardCollection(storeURL: storeURL)
        } catch {
            Logger(subsystem: "TCGCollect", category: "Collection").error("Collection unavailable: \(String(describing: error))")
            return nil
        }
    }
}

private struct NoCardPriceHistoryLoader: CardPriceHistoryLoader {
    func loadPriceHistory(for cardIDs: [Card.ID], days: Int?) async throws -> [PricePoint] {
        []
    }
}

private struct NoCardDetailsLoader: CardDetailsLoader {
    func loadDetails(for cardID: Card.ID) async throws -> GameDetails? {
        nil
    }
}
