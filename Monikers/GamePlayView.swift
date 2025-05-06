import SwiftUI

struct GamePlayView: View {
    @ObservedObject var game: Game
    @Environment(\.presentationMode) var presentationMode
    /// Callback invoked when the view ends (disappears).
    let onEnd: () -> Void

    /// Create a GamePlayView with an optional end callback.
    /// - Parameters:
    ///   - game: The Game view model to observe.
    ///   - onEnd: Closure called when the view disappears. Defaults to no-op.
    init(game: Game, onEnd: @escaping () -> Void = {}) {
        // Initialize the ObservedObject wrapper with the provided game
        self._game = ObservedObject(wrappedValue: game)
        self.onEnd = onEnd
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            VStack(spacing: 16) {
                // If not running, show interstitial/pass screen
                if !game.isRunning {
                    VStack(spacing: 12) {
                        Text(game.statusMessage)
                            .font(.title2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        // Allow ending the game early when between turns
                        if game.currentRound > 0 && game.currentRound <= 3 {
                            Button("End Game") {
                                game.endGame()
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.large)
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
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Turns: \(game.turnCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 20) {
                        Label("\(game.correctThisTurn)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(game.skippedThisTurn)", systemImage: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.yellow)
                    }
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
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.large)
                            .padding()
                    } else {
                        NavigationLink("Reviewed Cards", destination: ReviewedCardsView(game: game))
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.large)
                            .padding()
                    }
                }
            }
            .padding()
            .navigationTitle(game.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(game.isRunning ? "Stop" : "Start") {
                        if game.isRunning {
                            game.endTurn()
                        } else {
                            game.startTurn()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                }
            }
            .onDisappear {
                // Only call endGame if we're not navigating to evaluation or review
                // This prevents clearing the game state when going to review cards
                if game.currentRound <= 3 || game.hasReviewed {
                    game.endGame()
                }
                onEnd()
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
}
