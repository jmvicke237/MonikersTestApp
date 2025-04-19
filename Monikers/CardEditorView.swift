import SwiftUI

struct CardEditorView: View {
    @ObservedObject var game: Game
    @State private var newText: String = ""
    @State private var newIsFamily: Bool = false

    var body: some View {
        VStack {
            HStack {
                TextField("New card text", text: $newText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Toggle("Family", isOn: $newIsFamily)
                    .toggleStyle(SwitchToggleStyle())
                Button("Add") {
                    let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    // Append custom card with classification
                    game.cards.append(Card(text: trimmed, isFamily: newIsFamily))
                    newText = ""
                    newIsFamily = false
                }
            }
            .padding()

            List {
                // Only show custom cards, not seed cards
                ForEach(game.customCards) { card in
                    HStack {
                        Text(card.text)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { card.isFamily ?? false },
                            set: { newVal in game.updateCustomCardFamily(card: card, isFamily: newVal) }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete { indexSet in
                    let custom = game.customCards
                    for index in indexSet {
                        let cardToRemove = custom[index]
                        game.cards.removeAll { $0.id == cardToRemove.id }
                    }
                }
            }
        }
        .navigationTitle("Cards")
    }
}

struct CardEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CardEditorView(game: Game())
    }
}