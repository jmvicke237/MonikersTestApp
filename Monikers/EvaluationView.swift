import SwiftUI

/// View for reviewing cards after a game, allowing thumbs up, thumbs down, or question mark.
struct EvaluationView: View {
   @ObservedObject var game: Game
   @Environment(\.presentationMode) var presentationMode
   private enum Rating { case good, bad, unknown }
   @State private var ratings: [UUID: Rating] = [:]

   var body: some View {
       VStack {
           ScrollView {
               cardsReviewList
           }
           Button("Submit") {
               let good = game.selectedCards.filter { ratings[$0.id] == .good }
               let bad  = game.selectedCards.filter { ratings[$0.id] == .bad }
               game.applyEvaluation(good: good, bad: bad)
               presentationMode.wrappedValue.dismiss()
           }
           .buttonStyle(.borderedProminent)
           .padding()
       }
       .navigationTitle("Review Cards")
   }

   /// The scrollable list of cards with their rating buttons.
   private var cardsReviewList: some View {
       VStack(alignment: .leading, spacing: 16) {
           ForEach(game.selectedCards) { card in
               let rating = ratings[card.id] ?? .unknown
               VStack(alignment: .leading, spacing: 8) {
                   Text(card.text)
                       .font(.headline)
                   HStack(spacing: 20) {
                       Button { ratings[card.id] = .good } label: {
                           Image(systemName: "hand.thumbsup")
                               .foregroundColor(rating == .good ? .green : .primary)
                       }
                       Button { ratings[card.id] = .bad } label: {
                           Image(systemName: "hand.thumbsdown")
                               .foregroundColor(rating == .bad ? .red : .primary)
                       }
                       Button { ratings[card.id] = .unknown } label: {
                           Image(systemName: "questionmark.circle")
                               .foregroundColor(rating == .unknown ? .yellow : .primary)
                       }
                   }
               }
               Divider()
           }
       }
       .padding()
   }
}
