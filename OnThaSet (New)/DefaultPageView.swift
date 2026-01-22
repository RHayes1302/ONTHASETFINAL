//
//  DefaultPageView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct DefaultPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date) private var allEvents: [Event]
    @Query private var profiles: [UserProfile]
    
    @StateObject private var locationManager = LocationManager()
    @State private var showingLogin = false
    @State private var showingLimitAlert = false
    @State private var navigateToPost = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        
                        // 1. BRANDED HIGHWAY SHIELD HEADER
                        VStack(spacing: 0) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 85))
                                    .foregroundColor(.yellow)
                                
                                VStack(spacing: -2) {
                                    Text("ON")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundColor(.black)
                                    Text("THA")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.black)
                                    Text("SET")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(.black)
                                }
                                .offset(y: -4)
                            }
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 10)

                        // 2. LOGO PLACEHOLDER (Always visible)
                        Image("ONTHASET")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipped()
                            .border(Color.yellow.opacity(0.5), width: 1)

                        Text("What's On Tha Set Nearby")
                            .font(.title2.bold())
                            .foregroundColor(.yellow)

                        // 3. ACTION BUTTONS
                        VStack(spacing: 12) {
                            
                            NavigationLink(destination: EventHomeView(initialMode: .list)) {
                                makeMenuButton(text: "VIEW POSTED EVENTS")
                            }

                            NavigationLink(destination: NearbyEventsView()) {
                                makeMenuButton(text: "EVENTS NEARBY")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                locationManager.requestLocation()
                            })
                            
                            // NEW: WEATHER FORECAST BUTTON
                            NavigationLink(destination: WeatherView()) {
                                makeMenuButton(text: "RIDE FORECAST")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                // Request location for auto-populated weather
                                locationManager.requestLocation()
                            })

                            // PROTECTED POST BUTTON
                            Button(action: {
                                handlePostAttempt()
                            }) {
                                makeMenuButton(text: "POST EVENT")
                            }

                            NavigationLink(destination: AboutView()) {
                                makeMenuButton(text: "ABOUT")
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToPost) {
                AddEditEventView(
                    eventToEdit: Event(
                        title: "",
                        date: Date(),
                        category: .community,
                        locationName: "",
                        details: "",
                        securityCode: "",
                        price: "3.00",
                        latitude: 0.0,
                        longitude: 0.0
                    ),
                    onSave: { newEvent in
                        modelContext.insert(newEvent)
                        updatePostCount()
                        try? modelContext.save()
                    }
                )
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .alert("Monthly Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You have reached your limit of 4 posts this month.")
        }
    }

    // MARK: - Logic Helpers

    func handlePostAttempt() {
        guard let profile = profiles.first else {
            showingLogin = true
            return
        }
        
        checkAndResetMonthlyCount(profile: profile)
        
        if profile.postsThisMonth >= 4 {
            showingLimitAlert = true
        } else {
            navigateToPost = true
        }
    }

    func checkAndResetMonthlyCount(profile: UserProfile) {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let lastPostMonth = calendar.component(.month, from: profile.lastPostDate ?? Date.distantPast)
        
        if currentMonth != lastPostMonth {
            profile.postsThisMonth = 0
        }
    }

    func updatePostCount() {
        if let profile = profiles.first {
            profile.postsThisMonth += 1
            profile.lastPostDate = Date()
        }
    }

    func makeMenuButton(text: String) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.yellow)
            .cornerRadius(8)
    }
}
