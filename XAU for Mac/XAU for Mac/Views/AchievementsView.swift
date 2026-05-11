import SwiftUI

struct AchievementsView: View {
    let game: XboxGame
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var achievements: [XboxAchievement] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selection = Set<String>()
    @State private var sortOrder = [KeyPathComparator(\XboxAchievement.name)]
    
    enum AchievementColumn: String, CaseIterable, Identifiable {
        case id = "ID"
        case achievement = "Achievement"
        case description = "Description"
        case secret = "Secret"
        case dateUnlocked = "Date Unlocked"
        case gamerscore = "G's"
        case percentage = "%"
        case rarity = "Rarity"
        case state = "State"
        var id: String { self.rawValue }
    }
    
    @State private var visibleColumns: Set<AchievementColumn> = Set(AchievementColumn.allCases)
    
    enum AchievementFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
        var id: String { self.rawValue }
    }
    
    @State private var filterSelection: AchievementFilter = .all
    
    var filteredAchievements: [XboxAchievement] {
        var filtered = achievements
        
        // Filter by status
        switch filterSelection {
        case .unlocked:
            filtered = filtered.filter { $0.isUnlocked }
        case .locked:
            filtered = filtered.filter { !$0.isUnlocked }
        case .all:
            break
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        filtered.sort(using: sortOrder)
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && achievements.isEmpty {
                ProgressView("Loading Achievements...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filteredAchievements, selection: $selection, sortOrder: $sortOrder) {
                    // ID (Note: ID sorting might be tricky since it's index-based, usually games have an internal ID or index)
                    if visibleColumns.contains(.id) {
                        TableColumn("ID", value: \.id) { achievement in
                            let index = filteredAchievements.firstIndex(where: { $0.id == achievement.id }) ?? 0
                            let idText = String(index + 1)
                            Text(idText)
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(40.0)
                    }
                    
                    // Achievement
                    if visibleColumns.contains(.achievement) {
                        TableColumn("Achievement", value: \.name) { achievement in
                            achievementRow(achievement)
                        }
                        .width(200.0)
                    }
                    
                    // Description
                    if visibleColumns.contains(.description) {
                        TableColumn("Description", value: \.descriptionValue) { achievement in
                            Text(achievement.description ?? "Secret Achievement")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .width(150.0)
                    }
                    
                    // Secret
                    if visibleColumns.contains(.secret) {
                        TableColumn("Secret", value: \.isSecretValue) { achievement in
                            Text(achievement.isSecret ? "True" : "False")
                                .foregroundColor(achievement.isSecret ? .orange : .secondary)
                        }
                        .width(60.0)
                    }
                    
                    // Date Unlocked
                    if visibleColumns.contains(.dateUnlocked) {
                        TableColumn("Date Unlocked", value: \.progression.timeUnlockedValue) { achievement in
                            Text(formatDate(achievement.progression.timeUnlocked))
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(160.0)
                    }
                    
                    // G's
                    if visibleColumns.contains(.gamerscore) {
                        TableColumn("G's", value: \.gamerscoreValue) { achievement in
                            Text(achievement.rewards.first?.value ?? "0")
                                .fontWeight(.bold)
                        }
                        .width(40.0)
                    }
                    
                    // %
                    if visibleColumns.contains(.percentage) {
                        TableColumn("%", value: \.rarity.currentPercentage) { achievement in
                            Text(String(format: "%.2f", achievement.rarity.currentPercentage))
                                .foregroundColor(.secondary)
                        }
                        .width(60.0)
                    }
                    
                    // Rarity
                    if visibleColumns.contains(.rarity) {
                        TableColumn("Rarity", value: \.rarity.currentCategory) { achievement in
                            Text(achievement.rarity.currentCategory)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.1)))
                        }
                        .width(80.0)
                    }
                    
                    // State
                    if visibleColumns.contains(.state) {
                        TableColumn("State", value: \.progressState) { achievement in
                            Text(achievement.progressState)
                                .foregroundColor(achievement.isUnlocked ? .green : .secondary)
                                .fontWeight(achievement.isUnlocked ? .bold : .regular)
                        }
                        .width(100.0)
                    }
                }
            }
        }
        .navigationTitle(game.name)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Achievements")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(AchievementColumn.allCases) { column in
                        Toggle(column.rawValue, isOn: Binding(
                            get: { visibleColumns.contains(column) },
                            set: { isVisible in
                                if isVisible {
                                    visibleColumns.insert(column)
                                } else {
                                    visibleColumns.remove(column)
                                }
                            }
                        ))
                    }
                } label: {
                    Label("Columns", systemImage: "sidebar.right")
                }
                .help("Show/Hide Columns")
                
                Picker("Show", selection: $filterSelection) {
                    ForEach(AchievementFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
        }
        .task {
            await loadAchievements()
        }
    }
    
    @ViewBuilder
    private func achievementRow(_ achievement: XboxAchievement) -> some View {
        let imageUrlString = achievement.mediaAssets.first?.url
        
        HStack {
            CachedAsyncImage(url: imageUrlString)
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 48, height: 27)
                .cornerRadius(3)
                .saturation(achievement.isUnlocked ? 1.0 : 0.0)
                .opacity(achievement.isUnlocked ? 1.0 : 0.6)
                .onTapGesture {
                    if let urlStr = imageUrlString, let url = URL(string: urlStr) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            
            Text(achievement.name)
                .fontWeight(.semibold)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
        }
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "1/1/0001 8:00:00 AM" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let output = DateFormatter()
            output.dateStyle = .short
            output.timeStyle = .medium
            return output.string(from: date)
        }
        return dateString
    }
    
    private func loadAchievements() async {
        guard let xuid = xboxService.xuid else { return }
        if achievements.isEmpty {
            isLoading = true
        }
        
        do {
            achievements = try await xboxService.fetchAchievements(xuid: xuid, titleId: game.titleId)
        } catch {
            print("Error fetching achievements: \(error)")
        }
        isLoading = false
    }
}
