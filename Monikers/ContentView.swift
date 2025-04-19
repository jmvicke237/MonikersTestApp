//
//  ContentView.swift
//  Monikers
//
//  Created by Justin Vickers on 4/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var game = Game()
    @State private var isGameActive = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Add/Edit Cards feature removed; using only seed decks via "Use Family Deck" toggle
                HStack {
                    Text("Cards per Game:")
                    Picker(selection: $game.cardsPerGame, label: Text("")) {
                        ForEach([5, 10, 15, 20, 25, 30], id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.menu)
                }
                // Toggle between base and family decks
                Toggle("Use Family Deck", isOn: $game.useFamilyCards)
                    .padding(.horizontal)
                // Programmatic navigation to GamePlayView; onEnd resets game and returns home
                NavigationLink(destination: GamePlayView(game: game, onEnd: {
                    game.endGame()
                    isGameActive = false
                }), isActive: $isGameActive) {
                    EmptyView()
                }
                .hidden()
                Button("Start Game") {
                    isGameActive = true
                }
                NavigationLink("Reviewed Cards", destination: ReviewedCardsView(game: game))
                Button("Reset Reviews") {
                    game.resetReviews()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Monikers")
        }
    }
}

#Preview {
    ContentView()
}
