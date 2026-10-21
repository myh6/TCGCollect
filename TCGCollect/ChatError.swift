//
//  ChatError.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/21.
//

/// What went wrong while getting an answer, with the message to show the user.
nonisolated enum ChatError: Error, Equatable {
    case couldNotLoadAnswer

    var message: String {
        switch self {
        case .couldNotLoadAnswer:
            "Couldn't get an answer. Please try again."
        }
    }
}
