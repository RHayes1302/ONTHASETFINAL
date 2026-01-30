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
    @State private var timeFilter: TimeFilter = .nextMonth

    enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case nextMonth = "Next Month"
        case all = "All Upcoming"
        
        var displayName: String { rawValue }
    }

    var nearbyEvents: [Event] {
        let filtered = allEvents.filter { event in
            // Filter by location
            let isNearby = locationService.isNearby(event: event, radiusInMiles: searchRadius)
            
            // Filter by time
            let isInTimeRange = isEventInTimeRange(event)
            
            return isNearby && isInTimeRange
        }
        
        return filtered
    }
    
    private func isEventInTimeRange(_ event: Event) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Event must be in the future
        guard event.date >= now else { return false }
        
        switch timeFilter {
        case .today:
            return calendar.isDateInToday(event.date)
            
        case .thisWeek:
            guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
            return event.date <= weekFromNow
            
        case .nextMonth:
            guard let monthFromNow = calendar.date(byAdding: .month, value: 1, to: now) else { return false }
            return event.date <= monthFromNow
            
        case .all:
            return true // All future events
        }
    }
    
    // Helper to check if event is within the next week
    private func isEventThisWeek(_ event: Event) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        guard event.date >= now else { return false }
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
        
        return event.date <= weekFromNow
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
                
                // TIME FILTER
                VStack(spacing: 8) {
                    Text("Time Range")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                Button(action: { timeFilter = filter }) {
                                    Text(filter.displayName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(timeFilter == filter ? Color.yellow : Color.white.opacity(0.1))
                                        .foregroundColor(timeFilter == filter ? .black : .white)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
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
                    // Have location but no nearby events in time range
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow.opacity(0.3))
                        
                        Text("No events found")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("No events within \(Int(searchRadius)) miles in the \(timeFilter.displayName.lowercased()) timeframe")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        if let location = locationService.userLocation {
                            Text("Your location: \(String(format: "%.2f", location.coordinate.latitude)), \(String(format: "%.2f", location.coordinate.longitude))")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        
                        VStack(spacing: 12) {
                            if searchRadius < 200 {
                                Button(action: {
                                    searchRadius = min(searchRadius * 2, 200)
                                }) {
                                    Text("EXPAND RADIUS TO \(Int(min(searchRadius * 2, 200))) MILES")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.yellow)
                                        .cornerRadius(5)
                                }
                            }
                            
                            if timeFilter != .all {
                                Button(action: {
                                    timeFilter = .all
                                }) {
                                    Text("SHOW ALL UPCOMING EVENTS")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.yellow.opacity(0.7))
                                        .cornerRadius(5)
                                }
                            }
                            
                            Button(action: { locationService.requestLocation() }) {
                                Text("REFRESH LOCATION")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow.opacity(0.5))
                                    .cornerRadius(5)
                            }
                        }
                        
                        Spacer()
                    }
                } else {
                    // Show nearby events
                    VStack(spacing: 0) {
                        // Event count header
                        HStack {
                            Text("\(nearbyEvents.count) event\(nearbyEvents.count == 1 ? "" : "s") found")
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                            Spacer()
                            Text(timeFilter.displayName)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        
                        List {
                            ForEach(nearbyEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    // Highlighted event row for events this week
                                    HighlightedEventRow(
                                        event: event,
                                        isHighlighted: isEventThisWeek(event)
                                    )
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
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestLocation()
        }
    }
}

// MARK: - Highlighted Event Row Component

struct HighlightedEventRow: View {
    let event: Event
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Mini Flyer Thumbnail
            if let data = event.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
                    .overlay(
                        // "THIS WEEK" badge for highlighted events
                        isHighlighted ?
                        VStack {
                            HStack {
                                Text("THIS WEEK")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(4)
                        : nil
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "music.note").foregroundColor(.yellow))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                // Title with highlight indicator
                HStack(spacing: 6) {
                    if isHighlighted {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    Text(event.title.uppercased())
                        .font(.headline)
                        .foregroundColor(isHighlighted ? .yellow : .white)
                }
                
                // Date with special formatting for this week
                HStack(spacing: 4) {
                    Image(systemName: isHighlighted ? "calendar.badge.exclamationmark" : "calendar")
                        .font(.caption2)
                        .foregroundColor(isHighlighted ? .yellow : .gray)
                    
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(isHighlighted ? .yellow : .white)
                }
                
                // Parse location to show venue name
                let locationParts = event.locationName.split(separator: "|").map { String($0) }
                if let venueName = locationParts.first {
                    Label(venueName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Label(event.locationName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron with highlight color
            Image(systemName: "chevron.right")
                .foregroundColor(isHighlighted ? .yellow : .gray)
        }
        .padding()
        .background(
            Group {
                if isHighlighted {
                    // Highlighted background with yellow glow
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.15), Color.yellow.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    // Normal background
                    Color.white.opacity(0.05)
                }
            }
        )
        .cornerRadius(12)
        .overlay(
            // Yellow border for highlighted events
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}
