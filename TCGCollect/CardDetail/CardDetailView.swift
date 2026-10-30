//
//  CardDetailView.swift
//  TCGCollect
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import SwiftUI
import AppCore
import HoloCard

struct CardDetailView: View {
    let viewModel: CardDetailViewModel
    let priceViewModel: CardPriceViewModel

    var body: some View {
        ScrollView {
            CardDetailContent(viewModel: viewModel, priceViewModel: priceViewModel)
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle(viewModel.card.name)
        .toolbarTitleDisplayMode(.inline)
        .task { await viewModel.loadDetails() }
        .task { await priceViewModel.load() }
    }
}

struct CardDetailContent: View {
    let viewModel: CardDetailViewModel
    let priceViewModel: CardPriceViewModel

    private var card: CardDetailPresentation { viewModel.card }

    var body: some View {
        VStack(spacing: 24) {
            holoCard
            header
            CardPriceSection(viewModel: priceViewModel)
            detailsSection
        }
    }

    private var holoCard: some View {
        HoloCardView(style: card.holoStyle, cornerRadius: 14) {
            CardImageView(url: card.imageURL)
                .aspectRatio(63.0 / 88.0, contentMode: .fit)
        }
        .frame(maxWidth: 280)
        .padding(.top, 36)
        .padding(.bottom, 12)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(card.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if let details = card.details {
                Text(details)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
            if let setName = card.setName {
                Text(setName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let printing = card.printing {
                Text(printing)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        switch viewModel.details {
        case .idle, .loading:
            ProgressView("Loading details…")
                .padding()
        case .loaded(.some(.onePiece(let details))):
            OnePieceDetailsSection(details: OnePieceDetailsPresentation(details))
        case .loaded(.none):
            Text("No details for this card yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
        case .failed:
            VStack(spacing: 12) {
                Text("Couldn't load this card's details.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    Task { await viewModel.loadDetails() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

struct OnePieceDetailsSection: View {
    let details: OnePieceDetailsPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            categoryAndColors
            if !details.stats.isEmpty {
                stats
            }
            if !details.attributes.isEmpty || !details.types.isEmpty {
                attributesAndTypes
            }
            if let effect = details.effect {
                EffectText(markdown: effect)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryAndColors: some View {
        HStack(spacing: 12) {
            CapsuleBadge(details.category, font: .subheadline.weight(.semibold))
            HStack(spacing: 4) {
                ForEach(details.colors, id: \.self) { color in
                    Circle()
                        .fill(color.swatch)
                        .overlay(Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1))
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityHidden(true)
            if let colorNames = details.colorNames {
                Text(colorNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            ForEach(details.stats, id: \.label) { stat in
                VStack(spacing: 2) {
                    Text(stat.value)
                        .font(.title3.weight(.semibold).monospacedDigit())
                    Text(stat.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var attributesAndTypes: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !details.attributes.isEmpty {
                badges(titled: "Attribute", details.attributes)
            }
            if !details.types.isEmpty {
                badges(titled: "Type", details.types)
            }
        }
    }

    private func badges(titled title: LocalizedStringKey, _ names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout {
                ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                    CapsuleBadge(name)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CapsuleBadge: View {
    private let text: String
    private let font: Font

    init(_ text: String, font: Font = .subheadline) {
        self.text = text
        self.font = font
    }

    var body: some View {
        Text(text)
            .font(font)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

struct EffectText: View {
    let markdown: String

    var body: some View {
        Text(attributedEffect)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    private var attributedEffect: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
    }
}

private extension OnePieceDetails.Color {
    var swatch: Color {
        switch self {
        case .red: .red
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .black: .black
        case .yellow: .yellow
        }
    }
}

#if DEBUG
private nonisolated struct PreviewDetailsLoader: CardDetailsLoader {
    let result: Result<GameDetails?, Error>?

    func loadDetails(for cardID: Card.ID) async throws -> GameDetails? {
        guard let result else {
            try await Task.sleep(for: .seconds(3600))
            throw CancellationError()
        }
        return try result.get()
    }
}

private nonisolated struct PreviewPriceHistoryLoader: CardPriceHistoryLoader {
    func loadPriceHistory(for cardIDs: [Card.ID], days: Int?) async throws -> [PricePoint] {
        let prices: [Decimal] = [4.43, 4.50, 4.48, 4.62, 4.70, 4.66, 4.84, 4.95, 4.90, 4.85]
        return prices.enumerated().map { index, price in
            PricePoint(
                cardID: cardIDs[0],
                date: Date.now.addingTimeInterval(TimeInterval(index - prices.count) * 3 * 86_400),
                price: Money(amount: price, currencyCode: "USD")
            )
        }
    }
}

private let previewCard = Card(
    id: 675180,
    name: "Uta",
    number: "ST05-008",
    setName: "Starter Deck 5: ONE PIECE FILM edition",
    rarity: "C",
    printing: "Foil"
)

private let previewCharacterDetails = GameDetails.onePiece(OnePieceDetails(
    category: .character,
    colors: [.green],
    cost: 3,
    power: 4000,
    counter: 1000,
    attributes: ["Special"],
    types: ["FILM"],
    effect: "[Blocker] *(After your opponent declares an attack, you may rest this card to make it the new target of the attack.)*\n[End of Your Turn] **You may trash 1 Event from your hand**: Set up to 1 of your [FILM] type Characters as active."
))

private let previewLeaderDetails = GameDetails.onePiece(OnePieceDetails(
    category: .leader,
    colors: [.red, .green],
    power: 5000,
    life: 4,
    attributes: ["Strike", "Special"],
    types: ["Impel Down", "Whitebeard Pirates", "Straw Hat Crew"],
    effect: "If you have a Character with 7000 base power or more, give this Leader −2000 power.\n[Opponent's Turn] All of your [Portgas.D.Ace] and [Monkey.D.Luffy] cards gain +3000 power."
))

private let previewShanksDetails = GameDetails.onePiece(OnePieceDetails(
    category: .leader,
    colors: [.purple],
    power: 5000,
    life: 5,
    attributes: ["Slash"],
    types: ["FILM", "The Four Emperors", "Red-Haired Pirates"],
    effect: "[Activate: Main] [Once Per Turn] DON!! −3 *(You may return the specified number of DON!! cards from your field to your DON!! deck.)*: All of your {FILM} type Characters gain +2000 power during this turn."
))

@MainActor
private func detailView(_ card: Card, details: Result<GameDetails?, Error>?) -> some View {
    NavigationStack {
        CardDetailView(
            viewModel: CardDetailViewModel(card: card, loader: PreviewDetailsLoader(result: details)),
            priceViewModel: CardPriceViewModel(cardID: card.id, loader: PreviewPriceHistoryLoader())
        )
    }
}

#Preview("Foil Leader with card image") {
    detailView(
        Card(
            id: 676552,
            name: "Shanks",
            number: "ST05-001",
            setName: "ST-05: Starter Deck 5 Film Edition",
            imageURL: URL(string: "https://product-images.tcgplayer.com/fit-in/400x400/477316.jpg"),
            rarity: "L",
            printing: "Foil"
        ),
        details: .success(previewShanksDetails)
    )
    .environment(\.imageLoader, ImageLoader(dataLoader: ImageComposer.makeRemoteImageDataLoader(), memoryCache: ImageMemoryCache()))
}

#Preview("Character") {
    detailView(previewCard, details: .success(previewCharacterDetails))
}

#Preview("Leader, normal printing") {
    detailView(
        Card(id: 1, name: "Luffy & Ace", number: "ST30-001", setName: "ST-30: Starter Deck 30 EX Luffy & Ace", rarity: "L", printing: "Normal"),
        details: .success(previewLeaderDetails)
    )
}

#Preview("Loading") {
    detailView(previewCard, details: nil)
}

#Preview("No details") {
    detailView(previewCard, details: .success(nil))
}

#Preview("Failed") {
    detailView(previewCard, details: .failure(CancellationError()))
}
#endif
