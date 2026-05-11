import SwiftUI

struct AchievementsView: View {
    let game: XboxGame
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var achievements: [XboxAchievement] = []
    @State private var isLoading = false
    @State private var unlockingIds = Set<String>()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(achievements) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isUnlocking: unlockingIds.contains(achievement.id),
                        onUnlock: {
                            unlockSingle(achievementId: achievement.id)
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // Spoof Button
                        Button(action: {
                            if xboxService.spoofingTitleId == game.titleId {
                                xboxService.stopHeartbeat()
                            } else {
                                xboxService.startHeartbeat(titleId: game.titleId)
                            }
                        }) {
                            Label(
                                xboxService.spoofingTitleId == game.titleId ? "Stop Spoof" : "Spoof Playing",
                                systemImage: xboxService.spoofingTitleId == game.titleId ? "stop.circle.fill" : "play.circle.fill"
                            )
                        }
                        .tint(xboxService.spoofingTitleId == game.titleId ? .red : .accentColor)
                        .help("Simulate playing this game on your profile")
                    }
                }
            }
        }
        .navigationTitle(game.name)
        .task {
            await loadAchievements()
        }
    }
    
    private func loadAchievements() async {
        guard let xuid = xboxService.xuid else { return }
        if xboxService.achievementsCache[game.titleId] == nil {
            isLoading = true
        } else {
            achievements = xboxService.achievementsCache[game.titleId] ?? []
        }
        
        do {
            achievements = try await xboxService.fetchAchievements(xuid: xuid, titleId: game.titleId)
        } catch {
            print("Error fetching achievements: \(error)")
        }
        isLoading = false
    }
    
    func unlockSingle(achievementId: String) {
        guard let xuid = xboxService.xuid, let scid = game.serviceConfigId else { return }
        
        unlockingIds.insert(achievementId)
        Task {
            do {
                try await xboxService.unlockAchievements(
                    xuid: xuid,
                    titleId: game.titleId,
                    scid: scid,
                    achievementIds: [achievementId]
                )
                // Refresh
                achievements = try await xboxService.fetchAchievements(xuid: xuid, titleId: game.titleId)
            } catch {
                print("Unlock failed: \(error)")
            }
            unlockingIds.remove(achievementId)
        }
    }
    

}

struct AchievementRow: View {
    let achievement: XboxAchievement
    let isUnlocking: Bool
    let onUnlock: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: achievement.mediaAssets.first?.url)
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 80, height: 45)
                .clipped()
                .cornerRadius(4)
                .saturation(achievement.isUnlocked ? 1.0 : 0.0)
                .opacity(achievement.isUnlocked ? 1.0 : 0.6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                if let desc = achievement.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Gamerscore
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 16, height: 16)
                        Text("G")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                    }
                    Text(achievement.rewards.first?.value ?? "0")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
                
                // Unlock Button
                Button(action: onUnlock) {
                    ZStack {
                        if isUnlocking {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: achievement.isUnlocked ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(achievement.isUnlocked ? .accentColor : .black)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(achievement.isUnlocked ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .disabled(achievement.isUnlocked || isUnlocking)
                .onHover { hovering in
                    if !achievement.isUnlocked {
                        isHovering = hovering
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
