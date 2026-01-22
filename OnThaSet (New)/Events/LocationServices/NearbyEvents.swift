//
//  NearbyEvents.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

struct NearbyEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationService = LocationManager()
    @Query(sort: \Event.date) var allEvents: [Event]
    
    @State private var searchRadius: Double = 50 // miles

    var nearbyEvents: [Event] {
        allEvents.filter { locationService.isNearby(event: $0, radiusInMiles: searchRadius) }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // BRANDED HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                            .font(.title2.bold())
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.yellow)
                        
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 11, weight: .black))
                            Text("THA").font(.system(size: 9, weight: .black))
                            Text("SET").font(.system(size: 15, weight: .black))
                        }
                        .foregroundColor(.black)
                        .offset(y: -3)
                    }
                    
                    Spacer()
                    
                    Button(action: { locationService.requestLocation() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // RADIUS SELECTOR
                VStack(spacing: 8) {
                    Text("Search Radius: \(Int(searchRadius)) miles")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    HStack(spacing: 12) {
                        ForEach([25.0, 50.0, 100.0, 200.0], id: \.self) { radius in
                            Button(action: { searchRadius = radius }) {
                                Text("\(Int(radius))mi")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(searchRadius == radius ? Color.yellow : Color.white.opacity(0.1))
                                    .foregroundColor(searchRadius == radius ? .black : .white)
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 15)

                // CONTENT AREA
                if locationService.userLocation == nil {
                    // No location yet
                    VStack(spacing: 20) {
                        Spacer()
                        
                        if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                            // Permission denied
                            Image(systemName: "location.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.red.opacity(0.5))
                            
                            Text("Location Access Denied")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Please enable location services in Settings to find nearby events")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("OPEN SETTINGS")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else {
                            // Loading location
                            ProgressView()
                                .tint(.yellow)
                            
                            Text("Finding your location...")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: { locationService.requestLocation() }) {
                                Text("RETRY")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        }
                        
                        Spacer()
                    }
                } else if nearbyEvents.isEmpty {
                    // Have location but no nearby events
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow.opacity(0.3))
                        
                        Text("No events within \(Int(searchRadius)) miles")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if let location = locationService.userLocation {
                            Text("Your location: \(String(format: "%.2f", location.coordinate.latitude)), \(String(format: "%.2f", location.coordinate.longitude))")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        
                        Button(action: {
                            searchRadius = min(searchRadius * 2, 500) // Increase radius
                        }) {
                            Text("EXPAND SEARCH TO \(Int(searchRadius * 2)) MILES")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                        .disabled(searchRadius >= 500)
                        
                        Button(action: { locationService.requestLocation() }) {
                            Text("REFRESH LOCATION")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.yellow.opacity(0.5))
                                .cornerRadius(5)
                        }
                        Spacer()
                    }
                } else {
                    // Show nearby events
                    List {
                        ForEach(nearbyEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(event: event)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(.gray.opacity(0.2))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestLocation()
        }
    }
}
