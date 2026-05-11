import Foundation
import SwiftUI
import AuthenticationServices
import Combine

@MainActor
class XboxLiveService: ObservableObject {
    static let shared = XboxLiveService()
    
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var xauth: String?
    @Published var xuid: String?
    @Published var gamertag: String?
    
    // In-memory cache for fast switching
    var gamesCache: [XboxGame]?
    var achievementsCache: [String: [XboxAchievement]] = [:] // key: titleId
    
    private let session = URLSession.shared
    
    private init() {
        // Load from Keychain or UserDefaults in a real app
    }
    
    func login() async {
        // In a real macOS app, we would use ASWebAuthenticationSession
        // This is a complex flow, so I'll implement a robust skeleton
        // For now, please use the "Enter Token Manually" option in the UI.
    }
    
    func fetchGameDetails(titleId: String) async throws -> XboxGame? {
        guard let xuid = xuid, let xauth = xauth else { throw XboxError.notLoggedIn }
        
        let urlString = String(format: XboxAPI.URLs.title, xuid)
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("2", forHTTPHeaderField: "x-xbl-contract-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "pfns": [],
            "titleIds": [titleId]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TitlesResponse.self, from: data)
        return response.titles.first
    }
    
    func fetchInitialInfo() async {
        guard let xauth = xauth else { return }
        print("Attempting to fetch initial info with token: \(xauth.prefix(20))...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: XboxAPI.URLs.gamertag)!
            var request = URLRequest(url: url)
            request.addValue(xauth, forHTTPHeaderField: "Authorization")
            request.addValue("2", forHTTPHeaderField: "x-xbl-contract-version")
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let errorBody = String(data: data, encoding: .utf8) ?? "No body"
                    print("Error Body: \(errorBody)")
                }
            }
            
            let decoder = JSONDecoder()
            // Try to be flexible with casing
            let profile = try decoder.decode(BasicProfileResponse.self, from: data)
            
            print("Successfully decoded profile for users: \(profile.profileUsers.count)")
            
            if let user = profile.profileUsers.first {
                self.xuid = user.id
                self.gamertag = user.settings.first(where: { $0.id == "Gamertag" })?.value
                print("Logged in as: \(self.gamertag ?? "Unknown") (XUID: \(self.xuid ?? "Unknown"))")
                self.isLoggedIn = true
            } else {
                print("No profile users found in response.")
            }
        } catch {
            print("Failed to fetch initial info error: \(error)")
        }
    }
    
    func fetchProfile(xuid: String) async throws -> Profile {
        guard let xauth = xauth else { throw XboxError.notLoggedIn }
        
        let urlString = String(format: XboxAPI.URLs.profile, xuid)
        var request = URLRequest(url: URL(string: urlString)!)
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("5", forHTTPHeaderField: "x-xbl-contract-version")
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Profile.self, from: data)
    }
    
    func fetchGames(xuid: String) async throws -> [XboxGame] {
        if let cached = gamesCache { return cached }
        
        guard let xauth = xauth else { throw XboxError.notLoggedIn }
        
        let urlString = String(format: XboxAPI.URLs.titles, xuid)
        var request = URLRequest(url: URL(string: urlString)!)
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("2", forHTTPHeaderField: "x-xbl-contract-version")
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TitlesResponse.self, from: data)
        gamesCache = response.titles
        return response.titles
    }
    
    func fetchAchievements(xuid: String, titleId: String) async throws -> [XboxAchievement] {
        if let cached = achievementsCache[titleId] { return cached }
        
        guard let xauth = xauth else { throw XboxError.notLoggedIn }
        
        let urlString = String(format: XboxAPI.URLs.achievements, xuid, titleId)
        var request = URLRequest(url: URL(string: urlString)!)
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("4", forHTTPHeaderField: "x-xbl-contract-version")
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(AchievementsResponse.self, from: data)
        achievementsCache[titleId] = response.achievements
        return response.achievements
    }
    
    func unlockAchievements(xuid: String, titleId: String, scid: String, achievementIds: [String]) async throws {
        guard let xauth = xauth else { throw XboxError.notLoggedIn }
        
        let signature = "RGFtbklHb3R0YU1ha2VUaGlzU3RyaW5nU3VwZXJMb25nSHVoLkRvbnRFdmVuS25vd1doYXRTaG91bGRCZUhlcmVEcmFmZlN0cmluZw=="
        
        // Use a more manual loop since we are in an async context
        for i in stride(from: 0, to: achievementIds.count, by: 50) {
            let end = min(i + 50, achievementIds.count)
            let chunk = Array(achievementIds[i..<end])
            
            let urlString = String(format: XboxAPI.URLs.updateAchievements, xuid, scid)
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            request.addValue(xauth, forHTTPHeaderField: "Authorization")
            request.addValue("2", forHTTPHeaderField: "x-xbl-contract-version")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("XboxServicesAPI/2021.10.20211005.0 c", forHTTPHeaderField: "User-Agent")
            request.addValue(signature, forHTTPHeaderField: "Signature")
            
            let body: [String: Any] = [
                "action": "progressUpdate",
                "titleId": titleId,
                "serviceConfigId": scid,
                "userId": xuid,
                "achievements": chunk.map { ["id": $0, "percentComplete": "100"] }
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("Unlocking chunk of \(chunk.count) achievements...")
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Unlock HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    print("Unlock Error Body: \(bodyStr)")
                    throw XboxError.apiError("Status \(httpResponse.statusCode): \(bodyStr)")
                }
            }
        }
    }

    @Published var spoofingTitleId: String?
    private var heartbeatTimer: Timer?
    
    func startHeartbeat(titleId: String) {
        stopTimer()
        spoofingTitleId = titleId
        
        Task {
            // First stop any existing heartbeat on the server
            await performStopHeartbeat()
            // Then start the new one
            await sendHeartbeatRequest(titleId: titleId)
            
            // Setup timer for periodic heartbeats
            setupTimer(for: titleId)
        }
    }
    
    private func setupTimer(for titleId: String) {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.sendHeartbeatRequest(titleId: titleId)
            }
        }
    }
    
    private func stopTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        spoofingTitleId = nil
    }
    
    func stopHeartbeat() {
        stopTimer()
        Task {
            await performStopHeartbeat()
        }
    }
    
    private func performStopHeartbeat() async {
        guard let xuid = xuid, let xauth = xauth else { return }
        
        let urlString = String(format: XboxAPI.URLs.heartbeat, xuid)
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("3", forHTTPHeaderField: "x-xbl-contract-version")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.addValue(Locale.current.identifier.replacingOccurrences(of: "_", with: "-"), forHTTPHeaderField: "Accept-Language")
        request.addValue("XboxServicesAPI/2021.10.20211005.0 c", forHTTPHeaderField: "User-Agent")
        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Spoof Stop Status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Spoof Stop network error: \(error)")
        }
    }
    
    private func sendHeartbeatRequest(titleId: String) async {
        guard let xuid = xuid, let xauth = xauth else { 
            print("Heartbeat skipped: Missing XUID or XAUTH")
            return 
        }
        
        let urlString = String(format: XboxAPI.URLs.heartbeat, xuid)
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Exact headers and behavior to match Windows version (XboxRestAPI.cs)
        request.addValue(xauth, forHTTPHeaderField: "Authorization")
        request.addValue("3", forHTTPHeaderField: "x-xbl-contract-version")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.addValue(Locale.current.identifier.replacingOccurrences(of: "_", with: "-"), forHTTPHeaderField: "Accept-Language")
        request.addValue("XboxServicesAPI/2021.10.20211005.0 c", forHTTPHeaderField: "User-Agent")
        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
        
        let body: [String: Any] = [
            "titles": [
                [
                    "id": titleId,
                    "state": "active",
                    "expiration": 600,
                    "sandbox": "RETAIL"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Heartbeat Sent - Title: \(titleId), Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                    let bodyStr = String(data: data, encoding: .utf8) ?? "No body"
                    print("Heartbeat Error: \(bodyStr)")
                }
            }
        } catch {
            print("Heartbeat network error: \(error)")
        }
    }
}

enum XboxError: Error {
    case notLoggedIn
    case unlockFailed
    case apiError(String)
}

// Minimal models for decoding
struct BasicProfileResponse: Codable {
    let profileUsers: [BasicProfileUser]
    
    enum CodingKeys: String, CodingKey {
        case profileUsers = "profileUsers"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try both camelCase and PascalCase
        if let users = try? container.decode([BasicProfileUser].self, forKey: .profileUsers) {
            self.profileUsers = users
        } else {
            let pascalContainer = try decoder.container(keyedBy: AnyKey.self)
            self.profileUsers = try pascalContainer.decode([BasicProfileUser].self, forKey: AnyKey(stringValue: "ProfileUsers")!)
        }
    }
}

struct BasicProfileUser: Codable {
    let id: String
    let settings: [ProfileSetting]
    
    enum CodingKeys: String, CodingKey {
        case id, settings
    }
    
    init(from decoder: Decoder) throws {
        let pascalContainer = try decoder.container(keyedBy: AnyKey.self)
        self.id = try (try? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "id")!)) ?? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "Id")!)
        self.settings = try (try? pascalContainer.decode([ProfileSetting].self, forKey: AnyKey(stringValue: "settings")!)) ?? pascalContainer.decode([ProfileSetting].self, forKey: AnyKey(stringValue: "Settings")!)
    }
}

struct ProfileSetting: Codable {
    let id: String
    let value: String
    
    init(from decoder: Decoder) throws {
        let pascalContainer = try decoder.container(keyedBy: AnyKey.self)
        self.id = try (try? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "id")!)) ?? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "Id")!)
        self.value = try (try? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "value")!)) ?? pascalContainer.decode(String.self, forKey: AnyKey(stringValue: "Value")!)
    }
}

// Helper for dynamic keys
struct AnyKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int?
    init?(intValue: Int) { return nil }
}

struct Profile: Codable {
    let people: [Person]
}

struct Person: Codable {
    let xuid: String
    let gamertag: String
    let displayPicRaw: String?
    let gamerScore: String
}

struct TitlesResponse: Codable {
    let titles: [XboxGame]
}

struct XboxGame: Codable, Identifiable {
    var id: String { titleId }
    let titleId: String
    let name: String
    let displayImage: String?
    let serviceConfigId: String?
    let achievement: AchievementStats
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.titleId = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "titleId")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "TitleId")!)
        self.name = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "name")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Name")!)
        self.displayImage = (try? container.decode(String.self, forKey: AnyKey(stringValue: "displayImage")!)) ?? (try? container.decode(String.self, forKey: AnyKey(stringValue: "DisplayImage")!))
        self.serviceConfigId = (try? container.decode(String.self, forKey: AnyKey(stringValue: "serviceConfigId")!)) ?? (try? container.decode(String.self, forKey: AnyKey(stringValue: "ServiceConfigId")!))
        self.achievement = try (try? container.decode(AchievementStats.self, forKey: AnyKey(stringValue: "achievement")!)) ?? container.decode(AchievementStats.self, forKey: AnyKey(stringValue: "Achievement")!)
    }
}

struct AchievementStats: Codable {
    let totalGamerscore: Int
    let currentGamerscore: Int
    let totalAchievements: Int
    let currentAchievements: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.totalGamerscore = try (try? container.decode(Int.self, forKey: AnyKey(stringValue: "totalGamerscore")!)) ?? container.decode(Int.self, forKey: AnyKey(stringValue: "TotalGamerscore")!)
        self.currentGamerscore = try (try? container.decode(Int.self, forKey: AnyKey(stringValue: "currentGamerscore")!)) ?? container.decode(Int.self, forKey: AnyKey(stringValue: "CurrentGamerscore")!)
        self.totalAchievements = try (try? container.decode(Int.self, forKey: AnyKey(stringValue: "totalAchievements")!)) ?? container.decode(Int.self, forKey: AnyKey(stringValue: "TotalAchievements")!)
        self.currentAchievements = try (try? container.decode(Int.self, forKey: AnyKey(stringValue: "currentAchievements")!)) ?? container.decode(Int.self, forKey: AnyKey(stringValue: "CurrentAchievements")!)
    }
}

struct AchievementsResponse: Codable {
    let achievements: [XboxAchievement]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.achievements = try (try? container.decode([XboxAchievement].self, forKey: AnyKey(stringValue: "achievements")!)) ?? container.decode([XboxAchievement].self, forKey: AnyKey(stringValue: "Achievements")!)
    }
}

struct XboxAchievement: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let progressState: String
    let rewards: [Reward]
    let mediaAssets: [MediaAsset]
    
    var isUnlocked: Bool {
        progressState == "Achieved"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.id = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "id")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Id")!)
        self.name = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "name")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Name")!)
        self.description = (try? container.decode(String.self, forKey: AnyKey(stringValue: "description")!)) ?? (try? container.decode(String.self, forKey: AnyKey(stringValue: "Description")!))
        self.progressState = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "progressState")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "ProgressState")!)
        self.rewards = try (try? container.decode([Reward].self, forKey: AnyKey(stringValue: "rewards")!)) ?? container.decode([Reward].self, forKey: AnyKey(stringValue: "Rewards")!)
        self.mediaAssets = try (try? container.decode([MediaAsset].self, forKey: AnyKey(stringValue: "mediaAssets")!)) ?? container.decode([MediaAsset].self, forKey: AnyKey(stringValue: "MediaAssets")!)
    }
}

struct Reward: Codable {
    let value: String
    let type: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.value = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "value")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Value")!)
        self.type = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "type")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Type")!)
    }
}

struct MediaAsset: Codable {
    let name: String
    let url: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        self.name = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "name")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Name")!)
        self.url = try (try? container.decode(String.self, forKey: AnyKey(stringValue: "url")!)) ?? container.decode(String.self, forKey: AnyKey(stringValue: "Url")!)
    }
}
