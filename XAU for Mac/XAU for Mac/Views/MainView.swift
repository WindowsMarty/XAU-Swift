import SwiftUI

struct MainView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var selectedTab: NavigationItem? = .home
    
    enum NavigationItem: Hashable {
        case home
        case games
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: NavigationItem.home) {
                    Label("Home", systemImage: "house")
                }
                NavigationLink(value: NavigationItem.games) {
                    Label("Games", systemImage: "gamecontroller")
                }
                
                Divider()
                
                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("XAU for Mac")
        } detail: {
            NavigationStack {
                if !xboxService.isLoggedIn && selectedTab != .settings {
                    LoginView()
                } else {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .games:
                        GamesListView()
                    case .settings:
                        SettingsView()
                    case .none:
                        Text("Select an item")
                    }
                }
            }
        }
    }
}

struct LoginView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @State private var isLoggingIn = false
    @State private var manualToken = ""
    @State private var showManualEntry = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Welcome to Xbox Achievement Unlocker")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please login with your Microsoft account to continue.")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                if showManualEntry {
                    VStack(spacing: 8) {
                        TextField("Paste XBL3.0 Token here", text: $manualToken)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 400)
                        
                        Button("Login with Token") {
                            Task {
                                xboxService.xauth = manualToken
                                await xboxService.fetchInitialInfo()
                            }
                        }
                        .disabled(manualToken.isEmpty || xboxService.isLoading)
                        .buttonStyle(.borderedProminent)
                        .overlay {
                            if xboxService.isLoading {
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                } else {
                    Button("Start with XBL3.0 Token") {
                        withAnimation {
                            showManualEntry = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            Text("Note: This app uses OAuth flow for secure authentication.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
