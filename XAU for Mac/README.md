# XAU for Mac (Native Swift Version)

This is a native macOS port of the Xbox Achievement Unlocker, written in Swift and SwiftUI.

## Features Ported
- **Native macOS UI**: Built with SwiftUI for a premium look and feel.
- **Xbox Live Integration**: Ported logic for fetching profiles, games, and achievements.
- **Achievement Unlocking**: Core functionality to unlock title-based achievements.
- **OAuth Authentication**: Uses secure Microsoft OAuth flow.

## How to Build
1. Open **Xcode**.
2. Create a new **macOS App** project.
3. Name it `XAU for Mac`.
4. Replace the contents of the `XAU for Mac` folder in your new project with the files provided in this directory.
5. Ensure the following files are included in the project:
   - `XAUApp.swift` (App entry point)
   - `Views/MainView.swift`
   - `Views/HomeView.swift`
   - `Views/GamesListView.swift`
   - `Views/AchievementsView.swift`
   - `Views/SettingsView.swift`
   - `Services/XboxLiveService.swift`
   - `Services/XboxAPI.swift`
6. Add `AuthenticationServices` framework to your project for login support.
7. Build and Run (⌘R).

## Design Philosophy
The UI follows the latest macOS design language (Sonoma/Sequoia), featuring:
- **NavigationSplitView**: Standard sidebar navigation.
- **AsyncImage**: Smooth loading of game art and profile pictures.
- **SF Symbols**: Consistent iconography.
- **Responsive Layout**: Adapts to window resizing and full-screen mode.

## Note on Event-Based Achievements
This port currently focuses on **Title-Based** achievements. Event-based achievements require ETW (Event Tracing for Windows) or specialized network capturing which is platform-specific.
