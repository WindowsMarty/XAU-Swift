import SwiftUI

struct TitleSearchView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var searchText = ""
    @State private var results: [XboxGame] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search Game Titles (e.g. Minecraft)", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button("Search") {
                    performSearch()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if isSearching {
                ProgressView("Searching Catalog...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = searchError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "Search for Xbox games to find their Title IDs" : "No games found for \"\(searchText)\"")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(results) { game in
                    HStack(spacing: 16) {
                        CachedAsyncImage(url: game.displayImage)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.name)
                                .font(.headline)
                            
                            HStack {
                                Text("Title ID:")
                                    .foregroundColor(.secondary)
                                Text(game.titleId)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(game.titleId, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .help("Copy Title ID")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Title ID Search")
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                results = try await xboxService.searchTitles(query: query)
            } catch {
                searchError = "Search failed: \(error.localizedDescription)"
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
}
