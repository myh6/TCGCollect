//
//  TCGCollectApp.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/12.
//

import SwiftUI
import SwiftData
import AppCore
import os

@main
struct TCGCollectApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // Owned here, not by ChatView, so a request and its answer survive switching tabs.
    @State private var chatViewModel = Self.makeChatViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.text.bubble.right") {
                    NavigationStack {
                        if let chatViewModel {
                            ChatView(viewModel: chatViewModel)
                        } else {
                            ChatUnavailableView()
                        }
                    }
                }
                Tab("Collection", systemImage: "rectangle.stack") {
                    ContentView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// nil when the backend isn't configured, e.g. in Release builds for now.
    private static func makeChatViewModel() -> ChatViewModel? {
        do {
            let configuration = try BackendConfiguration(infoDictionary: Bundle.main.infoDictionary ?? [:])
            let loader = ChatComposer.makeChatLoader(baseURL: configuration.baseURL, apiKey: configuration.apiKey)
            return ChatViewModel(loader: loader)
        } catch {
            Logger(subsystem: "TCGCollect", category: "Chat").error("Chat unavailable: \(String(describing: error))")
            return nil
        }
    }
}
