//
//  OnThaSet__New_App.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//
import SwiftUI
import SwiftData

@main
struct OnThaSetApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
        .modelContainer(for: [Event.self, UserProfile.self])
    }
}
