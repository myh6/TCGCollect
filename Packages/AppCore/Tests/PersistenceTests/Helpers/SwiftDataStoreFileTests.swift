//
//  SwiftDataStoreFileTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/23.
//

import Testing

/// Every suite that sets up new SwiftData store files is nested in here, so they all run one at a time:
/// Core Data can crash when several new store files are set up at the same moment.
/// `.serialized` on each suite alone would still let two suites run at once.
@Suite(.serialized)
enum SwiftDataStoreFileTests {}
