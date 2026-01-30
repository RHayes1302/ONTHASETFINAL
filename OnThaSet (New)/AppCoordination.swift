//
//  AppCoordination.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/29/26.
//

import SwiftUI
import CoreLocation

/// Coordinator that manages app-level state including location authorization
class AppCoordinator: ObservableObject {
    @Published var shouldShowLocationPrompt = false
    @Published var hasCompletedOnboarding = false
    
    private let locationManager = CLLocationManager()
    
    init() {
        checkLocationAuthorizationStatus()
    }
    
    func checkLocationAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        
        // Check if we've already asked (stored in UserDefaults)
        let hasAskedBefore = UserDefaults.standard.bool(forKey: "HasAskedForLocation")
        
        switch status {
        case .notDetermined:
            // Only show prompt if we haven't asked before
            if !hasAskedBefore {
                shouldShowLocationPrompt = true
            }
        case .restricted, .denied:
            // User has denied or restricted - don't show prompt
            shouldShowLocationPrompt = false
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized - no prompt needed
            shouldShowLocationPrompt = false
        @unknown default:
            shouldShowLocationPrompt = false
        }
    }
    
    func completeLocationSetup() {
        // Mark that we've asked for location
        UserDefaults.standard.set(true, forKey: "HasAskedForLocation")
        shouldShowLocationPrompt = false
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        // For testing - reset the onboarding flow
        UserDefaults.standard.set(false, forKey: "HasAskedForLocation")
        shouldShowLocationPrompt = true
        hasCompletedOnboarding = false
    }
}

/// Wrapper view that shows location prompt on first launch
struct AppCoordinatorView<Content: View>: View {
    @StateObject private var coordinator = AppCoordinator()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .blur(radius: coordinator.shouldShowLocationPrompt ? 10 : 0)
            
            if coordinator.shouldShowLocationPrompt {
                LocationAuthorizationView(isPresented: $coordinator.shouldShowLocationPrompt)
                    .transition(.opacity)
                    .onChange(of: coordinator.shouldShowLocationPrompt) { _, newValue in
                        if !newValue {
                            coordinator.completeLocationSetup()
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.shouldShowLocationPrompt)
    }
}
