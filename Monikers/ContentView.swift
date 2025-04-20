//
//  ContentView.swift
//  Monikers
//
//  Created by Justin Vickers on 4/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var game = Game()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                VStack(spacing: 20) {
                    // Add/Edit Cards feature removed; using only seed decks via "Use Family Deck" toggle
                    HStack {
                        Text("Cards per Game:")
                            .foregroundColor(.white)
                        Picker(selection: $game.cardsPerGame, label: Text("")) {
                            ForEach([5, 10, 15, 20, 25, 30], id: \.self) { number in
                                Text("\(number)")
                                    .tag(number)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.white)
                    }
                    // Toggle between base and family decks
                    Toggle("Use Family Deck", isOn: $game.useFamilyCards)
                        .padding(.horizontal)
                    // Start Game button navigates to GamePlayView
                    NavigationLink("Start Game", destination: GamePlayView(game: game))
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.pink)
                    NavigationLink(destination: ReviewedCardsView(game: game)) {
                        Text("Reviewed Cards")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
                    .foregroundColor(.white)
                    Button("Reset Reviews") {
                        game.resetReviews()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                    Spacer()
                }
                .padding()
                .navigationTitle("Monikers")
            }
        }
    }
    
    // MARK: - Preview
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
