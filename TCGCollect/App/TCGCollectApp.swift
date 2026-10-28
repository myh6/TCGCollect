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
                        } else {
                            ChatUnavailableView()
                        }
                    }
                }
                Tab("Collection", systemImage: "rectangle.stack") {
                    NavigationStack {
                        if let collectionViewModel {
                            CollectionView(viewModel: collectionViewModel)
                        } else {
                            CollectionUnavailableView()
                        }
                    }
                }
                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    NavigationStack {
                        CardSearchView(ownedCards: ownedCardsSearch, onlineCards: onlineCardsSearch)
                    }
                }
            }
            .environment(\.imageLoader, imageLoader)
        }
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
