//
//  AddToCollectionControls.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/28.
//

import SwiftUI

/// `− n +`: how many copies to add. VoiceOver reads it as one adjustable control.
struct CopiesStepper: View {
    let copies: Int
    let range: ClosedRange<Int>
    var isEnabled = true
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack {
            Button("Fewer copies", systemImage: "minus", action: onDecrement)
                .disabled(!isEnabled || copies <= range.lowerBound)
            Text(copies, format: .number)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
            Button("More copies", systemImage: "plus", action: onIncrement)
                .disabled(!isEnabled || copies >= range.upperBound)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isEnabled ? .primary : .secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Copies")
        .accessibilityValue("\(copies)")
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: onIncrement()
            case .decrement: onDecrement()
            @unknown default: break
            }
        }
    }
}

struct AddToCollectionButton: View {
    let status: AddToCollectionViewModel.Status
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch status {
            case .notAdded:
                Label("Add", systemImage: "plus")
            case .adding:
                ProgressView()
                    .controlSize(.mini)
                    .accessibilityLabel("Adding")
            case .added:
                Label("Added", systemImage: "checkmark")
            case .failed:
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(status == .failed ? .red : nil)
        .disabled(status == .adding || status == .added)
        .frame(maxWidth: .infinity)
    }
}
