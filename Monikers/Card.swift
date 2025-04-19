import Foundation

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    /// Custom classification: nil for seed cards, true for custom family cards, false for custom base cards
    var isFamily: Bool?

    /// Initialize a card. For seed cards, leave isFamily nil. For custom cards, set isFamily accordingly.
    init(id: UUID = UUID(), text: String, isFamily: Bool? = nil) {
        self.id = id
        self.text = text
        self.isFamily = isFamily
    }
}