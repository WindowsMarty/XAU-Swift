//
//  XAU_for_MacApp.swift
//  XAU for Mac
//
//  Created by Marty on 2026.05.11.
//

import SwiftUI

@main
struct XAU_for_MacApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
    }
}
