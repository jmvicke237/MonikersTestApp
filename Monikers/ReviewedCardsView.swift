import SwiftUI

/// View to display cards that were reviewed as thumbs up or thumbs down.
struct ReviewedCardsView: View {
    @ObservedObject var game: Game

    var body: some View {
        List {
            if !game.reviewedGood.isEmpty {
                Section(header: Label("Good Cards", systemImage: "hand.thumbsup")) {
                    ForEach(game.reviewedGood) { card in
                        Text(card.text)
                    }
                }
            }
            if !game.reviewedBad.isEmpty {
                Section(header: Label("Bad Cards", systemImage: "hand.thumbsdown")) {
                    ForEach(game.reviewedBad) { card in
                        Text(card.text)
                    }
                }
            }
            if game.reviewedGood.isEmpty && game.reviewedBad.isEmpty {
                Text("No reviewed cards yet.")
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reviewed Cards")
    }
}

struct ReviewedCardsView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewedCardsView(game: Game())
    }
}