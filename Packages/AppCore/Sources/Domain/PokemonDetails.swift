public struct PokemonDetails: Hashable, Sendable {
    public enum Category: String, Hashable, Sendable {
        case pokemon, item, supporter, stadium, energy
    }

    public enum EnergyType: String, Hashable, Sendable {
        case grass, fire, water, lightning, psychic, fighting, darkness, metal, fairy, dragon, colorless
    }

    public let category: Category
    public let stage: String?
    public let hp: Int?
    public let energyTypes: [EnergyType]
    public let attacks: [String]
    public let weakness: String?
    public let resistance: String?
    public let retreatCost: Int?
    public let effect: String?
    public let flavorText: String?

    public init(
        category: Category,
        stage: String? = nil,
        hp: Int? = nil,
        energyTypes: [EnergyType] = [],
        attacks: [String] = [],
        weakness: String? = nil,
        resistance: String? = nil,
        retreatCost: Int? = nil,
        effect: String? = nil,
        flavorText: String? = nil
    ) {
        self.category = category
        self.stage = stage
        self.hp = hp
        self.energyTypes = energyTypes
        self.attacks = attacks
        self.weakness = weakness
        self.resistance = resistance
        self.retreatCost = retreatCost
        self.effect = effect
        self.flavorText = flavorText
    }
}
