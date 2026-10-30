//
//  SearchScope.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

nonisolated enum SearchScope: String, CaseIterable {
    case all
    case owned
    case online

    var showsOwned: Bool { self != .online }
    var showsOnline: Bool { self != .owned }
}
