import SwiftUI
import UIKit

struct GamePlayView: View {
    @ObservedObject var game: Game
    // Callback to end the game and return to home
    var onEnd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // If not running, show interstitial/pass screen
            if !game.isRunning {
                VStack(spacing: 12) {
                    Text(game.statusMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    // Allow ending the game early when between turns
                    if game.currentRound > 0 && game.currentRound <= 3 {
                        Button("End Game") {
                            game.endGame()
                            onEnd()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            // During an active turn, show the swipeable card
            else if let card = game.currentCard {
                SwipeCardView(
                    text: card.text,
                    onSwipeRight: { game.correctGuess() },
                    onSwipeLeft: { game.skipCard() }
                )
                .padding()
                Text("Time left: \(game.timeLeft)s")
                Text("Turns: \(game.turnCount)")
                // Per-turn counters
                Text("✅ \(game.correctThisTurn)   ➖ \(game.skippedThisTurn)")
            }
            // Fallback status
            else {
                Text(game.statusMessage)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
            // After game over, show review or reviewed-summary
            if game.currentRound > 3 {
                if !game.hasReviewed {
                    NavigationLink("Review Cards", destination: EvaluationView(game: game))
                        .padding()
                } else {
                    NavigationLink("Reviewed Cards", destination: ReviewedCardsView(game: game))
                        .padding()
                }
            }
        }
        .padding()
        .navigationTitle(game.title)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    game.endGame()
                    onEnd()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Monikers")
                    }
                }
            }
            if game.currentRound <= 3 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(game.isRunning ? "Stop" : "Start") {
                        if game.isRunning {
                            game.endTurn()
                        } else {
                            game.startTurn()
                        }
                    }
                }
            }
        }
    }
}

struct GamePlayView_Previews: PreviewProvider {
    static var previews: some View {
        GamePlayView(game: Game(), onEnd: {})
    }
}

/// A swipeable card view: swipe right to mark correct, left to skip, with haptic feedback.
struct SwipeCardView: View {
    let text: String
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void

    @State private var offset: CGSize = .zero
    private let feedback = UINotificationFeedbackGenerator()

    var body: some View {
        Text(text)
            .font(.largeTitle)
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 300)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(radius: 5)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        feedback.prepare()
                    }
                    .onEnded { gesture in
                        let threshold: CGFloat = 100
                        if gesture.translation.width > threshold {
                            feedback.notificationOccurred(.success)
                            withAnimation(.spring()) {
                                offset = CGSize(width: 600, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                                onSwipeRight()
                            }
                        } else if gesture.translation.width < -threshold {
                            feedback.notificationOccurred(.warning)
                            withAnimation(.spring()) {
                                offset = CGSize(width: -600, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                                onSwipeLeft()
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
    }
}
