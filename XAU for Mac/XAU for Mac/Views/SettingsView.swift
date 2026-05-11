import SwiftUI

struct SettingsView: View {
    @StateObject private var xboxService = XboxLiveService.shared
    @AppStorage("useFakeSignature") private var useFakeSignature = true
    @AppStorage("regionOverride") private var regionOverride = false
    
    var body: some View {
        Form {
            Section("Authentication") {
                if xboxService.isLoggedIn {
                    Text("Logged in as \(xboxService.gamertag ?? "Unknown")")
                    Button("Logout", role: .destructive) {
                        xboxService.isLoggedIn = false
                        xboxService.xauth = nil
                        xboxService.xuid = nil
                    }
                } else {
                    Text("Not logged in")
                }
            }
            
            Section("General Settings") {
                Toggle("Use Fake Signature", isOn: $useFakeSignature)
                Toggle("Region Override (en-GB)", isOn: $regionOverride)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Mac Native)")
                        .foregroundColor(.secondary)
                }
                
                Link("GitHub Project", destination: URL(string: "https://github.com/Fumo-Unlockers/Xbox-Achievement-Unlocker")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
