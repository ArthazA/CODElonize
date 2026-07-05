//
//  CODElonizeApp.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 02/07/26.
//

import SwiftUI

@main
struct CODElonizeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
