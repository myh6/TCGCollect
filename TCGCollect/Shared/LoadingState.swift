//
//  LoadingState.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

enum LoadingState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed
}
