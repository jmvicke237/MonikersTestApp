import Foundation
import Combine

/// Different phases of the game corresponding to each round's clue constraints.
enum RoundPhase: Int, CustomStringConvertible {
    case taboo = 1     // free-form guessing
    case oneWord = 2   // exactly one word
    case mime = 3      // no words

    var description: String {
        switch self {
        case .taboo: return "Taboo"
        case .oneWord: return "One Word"
        case .mime: return "Mime"
        }
    }
}

/// Core game logic for cooperative Monikers.
class Game: ObservableObject {
    /// All available cards (seed + custom).
    @Published var cards: [Card] = []
    /// The 20 randomly selected cards for this game session.
    @Published var selectedCards: [Card] = []
    /// The current deck for the active round, mutated as guesses are made.
    @Published var currentDeck: [Card] = []
    /// Index of the current card within `currentDeck`.
    @Published var currentIndex: Int = 0
    /// Current round number: 0 = not started, 1 = Taboo, 2 = One Word, 3 = Mime, >3 = game over.
    @Published var currentRound: Int = 0
    /// Total number of turns (players' 60s sessions) taken so far.
    @Published var turnCount: Int = 0
    /// Number of correct guesses in the current turn.
    @Published var correctThisTurn: Int = 0
    /// Number of skips in the current turn.
    @Published var skippedThisTurn: Int = 0
    /// Is a turn currently active/timer running?
    @Published var isRunning: Bool = false
    /// Seconds left in the current turn.
    @Published var timeLeft: Int = 10
    /// Cards reviewed as thumbs up.
    @Published var reviewedGood: [Card] = []
    /// Cards reviewed as thumbs down.
    @Published var reviewedBad: [Card] = []
    /// Has the evaluation been completed.
    @Published var hasReviewed: Bool = false
    /// Number of cards to use in each game session.
    @Published var cardsPerGame: Int = 20
    /// Toggle between base (default) and family seed decks.
    @Published var useFamilyCards: Bool = false
    /// Duration for each turn in seconds (for testing, 10s per turn).
    private let turnDuration: Int = 10

    private var timerCancellable: AnyCancellable?
    // Combine subscribers for auto-persistence
    private var cancellables = Set<AnyCancellable>()
    /// Helper to load seed card lines from a bundled text file.
    private func seedLines(from resourceName: String) -> [String] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return content
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
    /// All custom cards added by the user (cards with explicit classification).
    var customCards: [Card] {
        return cards.filter { $0.isFamily != nil }
    }
    
    /// Update the family classification of a custom card.
    func updateCustomCardFamily(card: Card, isFamily: Bool) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index].isFamily = isFamily
        }
    }

    init() {
        // Load saved cards and settings; fall back to seed cards
        loadPersistedState()
        // Always (re)load seed cards for the selected deck, filtering out reviewed
        loadSeedCards()
        // Automatically save when these properties change
        $cards
            .sink { [weak self] _ in self?.savePersistedState() }
            .store(in: &cancellables)
        $reviewedGood
            .sink { [weak self] _ in self?.savePersistedState() }
            .store(in: &cancellables)
        $reviewedBad
            .sink { [weak self] _ in self?.savePersistedState() }
            .store(in: &cancellables)
        $cardsPerGame
            .sink { [weak self] _ in self?.savePersistedState() }
            .store(in: &cancellables)
        // When deck type toggles, reload seed cards
        $useFamilyCards
            .dropFirst()
            .sink { [weak self] _ in self?.reloadSeeds() }
            .store(in: &cancellables)
    }

    private func loadSeedCards() {
        // Load seeds for the active deck, excluding reviewed cards; custom cards disabled
        let resourceName = useFamilyCards ? "family_cards" : "base_cards"
        let lines = seedLines(from: resourceName)
        let excluded = Set(reviewedGood.map { $0.text }).union(reviewedBad.map { $0.text })
        let seedLinesFiltered = lines.filter { !excluded.contains($0) }
        // Replace cards with seed-only cards
        cards = seedLinesFiltered.map { Card(text: $0) }
    }
    
    // MARK: - Persistence
    /// Load persisted cards, reviewed lists, and settings from UserDefaults.
    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "cards") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                cards = decoded
            }
        }
        if let data = defaults.data(forKey: "reviewedGood") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                reviewedGood = decoded
            }
        }
        if let data = defaults.data(forKey: "reviewedBad") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                reviewedBad = decoded
            }
        }
        let perGame = defaults.integer(forKey: "cardsPerGame")
        if perGame > 0 {
            cardsPerGame = perGame
        }
        // Load deck type toggle
        useFamilyCards = defaults.bool(forKey: "useFamilyCards")
    }

    /// Save current cards, reviewed lists, and settings to UserDefaults.
    private func savePersistedState() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(cards) {
            defaults.set(data, forKey: "cards")
        }
        if let data = try? JSONEncoder().encode(reviewedGood) {
            defaults.set(data, forKey: "reviewedGood")
        }
        if let data = try? JSONEncoder().encode(reviewedBad) {
            defaults.set(data, forKey: "reviewedBad")
        }
        defaults.set(cardsPerGame, forKey: "cardsPerGame")
        // Save deck type toggle
        defaults.set(useFamilyCards, forKey: "useFamilyCards")
    }

    /// Reload seed cards when switching between base and family decks.
    private func reloadSeeds() {
        loadSeedCards()
        savePersistedState()
    }
    
    /// Reset all reviewed status and reload seed decks.
    func resetReviews() {
        reviewedGood.removeAll()
        reviewedBad.removeAll()
        hasReviewed = false
        // Reload the seed cards for current deck type
        loadSeedCards()
        savePersistedState()
    }

    /// Computed phase based on `currentRound`.
    var phase: RoundPhase? {
        return RoundPhase(rawValue: currentRound)
    }

    /// Display title for the view based on game state.
    var title: String {
        if currentRound == 0 {
            return "Monikers"
        } else if currentRound <= 3, let phase = phase {
            return "Round \(currentRound): \(phase.description)"
        } else {
            return "Game Over"
        }
    }

    /// Status message when no current card is displayed.
    var statusMessage: String {
        if cards.isEmpty {
            return "No cards—add some first!"
        }
        if currentRound == 0 {
            return "Press Start to begin Round 1: \(RoundPhase.taboo.description)"
        }
        if currentRound > 3 {
            return "Game over! Total turns: \(turnCount)"
        }
        if currentDeck.isEmpty {
            let prevRound = currentRound - 1
            let prevName = RoundPhase(rawValue: prevRound)?.description ?? ""
            if currentRound <= 3 {
                let nextName = phase?.description ?? ""
                return "Round \(prevRound) (\(prevName)) complete! Press Start for Round \(currentRound) (\(nextName))."
            } else {
                return "Round \(prevRound) (\(prevName)) complete! Game over!"
            }
        }
        if !isRunning {
            // Prompt to pass device before starting next turn
            return "Pass to the next player! Press Start when ready."
        }
        return ""
    }

    /// Initialize the game by selecting up to `cardsPerGame` cards and resetting state.
    private func initializeGame() {
        // Reset after review/new session
        hasReviewed = false
        // Ensure cards pool matches current deck setting before selecting
        loadSeedCards()
        // Select up to cardsPerGame cards for this session
        if cards.count <= cardsPerGame {
            selectedCards = cards
        } else {
            selectedCards = Array(cards.shuffled().prefix(cardsPerGame))
        }
        currentRound = 1
        // Use the randomly-ordered selectedCards as the deck (preserve order across rounds)
        // Shuffle the selected cards for the first round
        currentDeck = selectedCards.shuffled()
        currentIndex = 0
        turnCount = 0
        timeLeft = turnDuration
    }

    /// Start a 60-second turn; if first turn, initialize game.
    func startTurn() {
        // Initialize a new game if not started or after finishing all rounds
        if currentRound == 0 || currentRound > 3 {
            initializeGame()
        }
        guard !isRunning, currentRound >= 1, currentRound <= 3 else { return }
        // Reset per-turn counters
        correctThisTurn = 0
        skippedThisTurn = 0
        // Shuffle remaining cards for the next player and start from the top
        currentDeck.shuffle()
        currentIndex = 0
        isRunning = true
        turnCount += 1
        timeLeft = turnDuration
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeLeft > 0 {
                    self.timeLeft -= 1
                } else {
                    self.endTurn()
                }
            }
    }

    /// Stop the current turn timer and mark as not running.
    private func stopTimer() {
        isRunning = false
        timerCancellable?.cancel()
    }

    /// End the current turn; if deck is empty, advance the round.
    func endTurn() {
        guard isRunning else { return }
        stopTimer()
        if currentDeck.isEmpty {
            advanceRound()
        }
    }

    /// Advance to the next round (or finish the game).
    private func advanceRound() {
        currentRound += 1
        stopTimer()
        if currentRound <= 3 {
            currentDeck = selectedCards.shuffled()
            currentIndex = 0
            timeLeft = turnDuration
        }
    }

    /// Handle a correct guess: remove the card from the deck.
    func correctGuess() {
        guard isRunning, currentDeck.indices.contains(currentIndex) else { return }
        // Count this correct guess
        correctThisTurn += 1
        // Remove the guessed card
        currentDeck.remove(at: currentIndex)
        if currentDeck.isEmpty {
            endTurn()
        } else if currentIndex >= currentDeck.count {
            currentIndex = 0
        }
    }

    /// Handle skipping a card: move it to the back of the deck.
    func skipCard() {
        guard isRunning, currentDeck.indices.contains(currentIndex) else { return }
        // Count this skip
        skippedThisTurn += 1
        // Move the card to the back of the deck
        let card = currentDeck.remove(at: currentIndex)
        currentDeck.append(card)
        if currentIndex >= currentDeck.count {
            currentIndex = 0
        }
    }

    /// The current card to display.
    var currentCard: Card? {
        guard currentDeck.indices.contains(currentIndex) else { return nil }
        return currentDeck[currentIndex]
    }
    /// Apply evaluation results: separate good and bad cards, remove them from future pool.
    func applyEvaluation(good: [Card], bad: [Card]) {
        reviewedGood.append(contentsOf: good)
        reviewedBad.append(contentsOf: bad)
        let removedIds = Set(good.map { $0.id } + bad.map { $0.id })
        cards.removeAll { removedIds.contains($0.id) }
        hasReviewed = true
    }
    
    /// End the current game session early and reset to home state.
    func endGame() {
        stopTimer()
        currentRound = 0
        // Clear session-specific cards and counters
        selectedCards = []
        currentDeck = []
        currentIndex = 0
        turnCount = 0
        correctThisTurn = 0
        skippedThisTurn = 0
        timeLeft = turnDuration
        hasReviewed = false
    }
}
