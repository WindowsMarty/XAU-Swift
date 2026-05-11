import SwiftUI

struct GamesListView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var games: [XboxGame] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    @State private var selectedFilter = "All"
    let filterOptions = ["All", "Xbox One/Series", "PC", "Xbox 360"]
    
    var filteredGames: [XboxGame] {
        var filtered = games
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        // Add more filter logic here if needed
        return filtered
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && games.isEmpty {
                ProgressView("Loading Games...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredGames) { game in
                            NavigationLink {
                                AchievementsView(game: game)
                            } label: {
                                GameCard(game: game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Filter or Enter Title ID")
                .onSubmit(of: .search) {
                    // If no match found, try to add by Title ID
                    if filteredGames.isEmpty {
                        addGameByTitleId()
                    }
                }
            }
        }
        .navigationTitle("Games")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    Task { await loadGames() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            if xboxService.xuid != nil, games.isEmpty {
                await loadGames()
            }
        }
    }
    
    private func loadGames() async {
        guard let xuid = xboxService.xuid else { return }
        
        // If we have cache, don't show the main spinner
        if xboxService.gamesCache == nil {
            isLoading = true
        }
        
        do {
            games = try await xboxService.fetchGames(xuid: xuid)
        } catch {
            print("Error fetching games: \(error)")
        }
        isLoading = false
    }
    
    private func addGameByTitleId() {
        let titleId = searchText.trimmingCharacters(in: .whitespaces)
        guard !titleId.isEmpty else { return }
        
        Task {
            isLoading = true
            do {
                if let newGame = try await xboxService.fetchGameDetails(titleId: titleId) {
                    if !games.contains(where: { $0.titleId == newGame.titleId }) {
                        withAnimation {
                            games.insert(newGame, at: 0)
                            searchText = ""
                        }
                    }
                }
            } catch {
                print("Error adding game by ID: \(error)")
            }
            isLoading = false
        }
    }
}

struct GameCard: View {
    let game: XboxGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedAsyncImage(url: game.displayImage)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                
                HStack {
                    if let stats = game.achievement {
                        Text("\(stats.currentGamerscore) / \(stats.totalGamerscore) G")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(Double(stats.currentGamerscore) / Double(max(1, stats.totalGamerscore)) * 100))%")
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(3)
                    } else {
                        Text("No stats available")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
