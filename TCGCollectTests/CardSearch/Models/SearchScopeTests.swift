//
//  SearchScopeTests.swift
//  TCGCollectTests
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import Testing
@testable import TCGCollect

struct SearchScopeTests {

    @Test(arguments: [
        (SearchScope.all, true, true),
        (.owned, true, false),
        (.online, false, true),
    ])
    func scope_showsItsSections(scope: SearchScope, showsOwned: Bool, showsOnline: Bool) {
        #expect(scope.showsOwned == showsOwned)
        #expect(scope.showsOnline == showsOnline)
    }

    @Test(arguments: [(SearchScope.all, "all"), (.owned, "owned"), (.online, "online")])
    func rawValue_staysTheSameForSaving(scope: SearchScope, rawValue: String) {
        #expect(scope.rawValue == rawValue)
    }
}
