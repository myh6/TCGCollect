//
//  PreviewCard.swift
//  HoloCard
//
//  Created by Min-Yang Huang on 2026/10/29.
//

#if DEBUG
import SwiftUI

struct PreviewCard: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [.orange, .red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .stroke(.yellow, lineWidth: 6)
                    .padding(30)
                Image(systemName: "figure.martial.arts")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(50)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview Card").font(.headline)
                Text("OP00-000 · SR").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.white)
        }
        .aspectRatio(63.0 / 88.0, contentMode: .fit)
        .background(.black)
    }
}
#endif
