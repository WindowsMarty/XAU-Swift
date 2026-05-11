import SwiftUI

struct HomeView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var profile: Person?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                if let person = profile {
                    // Profile Card
                    HStack(spacing: 24) {
                        AsyncImage(url: URL(string: person.displayPicRaw?.replacingOccurrences(of: "&mode=Padding", with: "") ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.secondary.opacity(0.2))
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.05), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(person.gamertag)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            Text("XUID: \(person.xuid)")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary.opacity(0.1))
                                        .frame(width: 18, height: 18)
                                    Text("G")
                                        .font(.system(size: 11, weight: .black))
                                }
                                
                                Text(person.gamerScore)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Quick Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT STATUS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(title: "Status", value: "Connected", icon: "antenna.radiowaves.left.and.right", color: .green)
                            StatCard(title: "Service", value: "Xbox Live", icon: "server.rack", color: .blue)
                            StatCard(title: "Protocol", value: "XBL 3.0", icon: "shield.authconfig", color: .purple)
                            StatCard(title: "Sandbox", value: "RETAIL", icon: "cube.box", color: .orange)
                        }
                    }
                } else if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    ContentUnavailableView("Profile Not Found", systemImage: "person.crop.circle.badge.exclamationmark", description: Text("Please ensure your token is valid."))
                }
            }
            .padding(30)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Profile")
        .task {
            if let xuid = xboxService.xuid {
                isLoading = true
                do {
                    let result = try await xboxService.fetchProfile(xuid: xuid)
                    profile = result.people.first
                } catch {
                    print("Error fetching profile: \(error)")
                }
                isLoading = false
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}
