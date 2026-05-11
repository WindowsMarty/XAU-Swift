import SwiftUI

struct HomeView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var profile: Person?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let person = profile {
                    // Profile Header
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: person.displayPicRaw?.replacingOccurrences(of: "&mode=Padding", with: "") ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.secondary.opacity(0.2))
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 4) {
                            Text(person.gamertag)
                                .font(.system(size: 24, weight: .bold))
                            
                            HStack(spacing: 8) {
                                Text("G")
                                    .font(.system(size: 12, weight: .black))
                                    .padding(4)
                                    .background(Circle().fill(Color.primary.opacity(0.1)))
                                
                                Text(person.gamerScore)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Details Group
                    GroupBox(label: Label("Account Details", systemImage: "person.text.rectangle")) {
                        VStack(spacing: 12) {
                            DetailRow(label: "XUID", value: person.xuid)
                            Divider()
                            DetailRow(label: "Reputation", value: person.xboxOneRep ?? "GoodPlayer")
                            Divider()
                            DetailRow(label: "Account Tier", value: person.accountTier ?? "Silver")
                            Divider()
                            DetailRow(label: "Location", value: person.location ?? "Not Set")
                            Divider()
                            DetailRow(label: "Tenure", value: person.tenure ?? "0")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Activity & Social Group
                    GroupBox(label: Label("Activity", systemImage: "chart.bar.fill")) {
                        VStack(spacing: 12) {
                            DetailRow(label: "Currently Playing", value: person.presenceText ?? "None")
                            Divider()
                            DetailRow(label: "Active Device", value: person.presenceDevice ?? "Unknown")
                            Divider()
                            HStack {
                                DetailRow(label: "Followers", value: "\(person.followerCount ?? 0)")
                                Spacer(minLength: 40)
                                DetailRow(label: "Following", value: "\(person.followingCount ?? 0)")
                            }
                            Divider()
                            DetailRow(label: "Verified", value: person.isVerified == true ? "Yes" : "No")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if let bio = person.bio, !bio.isEmpty {
                        GroupBox(label: Label("Bio", systemImage: "quote.bubble")) {
                            Text(bio)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                    }
                    
                } else if isLoading {
                    VStack {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading Profile...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    ContentUnavailableView {
                        Label("Profile Not Found", systemImage: "person.crop.circle.badge.exclamationmark")
                    } description: {
                        Text("Please ensure your token is valid and refresh.")
                    } actions: {
                        Button("Retry") {
                            Task { await refreshProfile(force: true) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(minHeight: 400)
                }
            }
            .padding(32)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task { await refreshProfile(force: true) }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh profile information")
            }
        }
        .task {
            await refreshProfile()
        }
    }
    
    private func refreshProfile(force: Bool = false) async {
        if let xuid = xboxService.xuid {
            // If we have cache and aren't forcing, load it instantly without spinner
            if !force, let cached = xboxService.profileCache {
                self.profile = cached
                return
            }
            
            // Only show spinner if we don't have data yet or are forcing a refresh
            if profile == nil || force {
                isLoading = true
            }
            
            do {
                let result = try await xboxService.fetchProfile(xuid: xuid, forceRefresh: force)
                profile = result.people.first
            } catch {
                print("Error fetching profile: \(error)")
            }
            isLoading = false
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}
