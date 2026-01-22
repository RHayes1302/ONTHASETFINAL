//
//  EventDetailView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var event: Event
    
    @State private var showingDeleteAlert = false
    @State private var showingEditAlert = false
    @State private var inputCode = ""
    @State private var showWeatherSheet = false
    @State private var showEditSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 1. PHOTO SECTION
                    if let uiImage = event.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: UIScreen.main.bounds.width - 32)
                            .frame(height: 300)
                            .clipped() // Prevents display extending past border
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // 2. TITLE
                        Text(event.title)
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.yellow)
                            .minimumScaleFactor(0.7) // Prevents title from pushing borders
                        
                        // 3. DATE & TIME
                        HStack {
                            Image(systemName: "calendar")
                            Text(event.date, style: .date)
                            Text("at")
                            Text(event.date, style: .time)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        
                        // 4. LOCATION
                        VStack(alignment: .leading, spacing: 8) {
                            if let venueName = getVenueName() {
                                HStack {
                                    Image(systemName: "building.2.fill")
                                    Text(venueName)
                                        .font(.headline)
                                }
                                .foregroundColor(.yellow)
                            }
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                Text(getAddress())
                            }
                            .foregroundColor(.gray)
                            
                            // Navigation Buttons (Back to Original HStack for reliability)
                            if !event.locationName.isEmpty {
                                HStack(spacing: 8) {
                                    Button(action: { openInWaze() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location.fill")
                                            Text("WAZE").font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: { openInAppleMaps() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "map.fill")
                                            Text("MAPS").font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: { openInGoogleMaps() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "map.circle.fill")
                                            Text("GOOGLE").font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.top, 5)
                            }
                        }
                        
                        // WEATHER BUTTON
                        if !event.locationName.isEmpty {
                            Button(action: { showWeatherSheet = true }) {
                                HStack {
                                    Image(systemName: "cloud.sun.fill").font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("CHECK RIDE FORECAST").font(.headline.bold())
                                        Text("For \(extractCityName())").font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow, lineWidth: 1))
                            }
                            .foregroundColor(.yellow)
                            .padding(.vertical, 5)
                        }
                        
                        Divider().background(Color.yellow.opacity(0.5))
                        
                        // 5. DETAILS
                        Text("DETAILS").font(.caption.bold()).foregroundColor(.yellow)
                        Text(event.details).foregroundColor(.white).lineSpacing(5)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                    
                    // 6. EDIT & DELETE BUTTONS
                    HStack(spacing: 12) {
                        Button(action: { showingEditAlert = true }) {
                            Label("Edit Event", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .cornerRadius(10)
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.yellow)
                        .font(.title2.bold())
                }
            }
        }
        .alert("Verify Security Code", isPresented: $showingEditAlert) {
            SecureField("Enter Code", text: $inputCode)
            Button("Cancel", role: .cancel) { inputCode = "" }
            Button("Verify & Edit") {
                if inputCode == event.securityCode || inputCode == "Pokemon122!!" {
                    inputCode = ""
                    showEditSheet = true
                } else {
                    inputCode = ""
                }
            }
        } message: {
            Text("Please enter the author's code or the Master Password to edit this event.")
        }
        .alert("Verify Security Code", isPresented: $showingDeleteAlert) {
            SecureField("Enter Code", text: $inputCode)
            Button("Cancel", role: .cancel) { inputCode = "" }
            Button("Verify & Delete", role: .destructive) {
                if inputCode == event.securityCode || inputCode == "Pokemon122!!" {
                    modelContext.delete(event)
                    try? modelContext.save()
                    dismiss()
                }
                inputCode = ""
            }
        } message: {
            Text("Please enter the author's code or the Master Password to delete this event.")
        }
        .sheet(isPresented: $showWeatherSheet) {
            if event.latitude != 0.0 && event.longitude != 0.0 {
                WeatherViewForCoordinates(latitude: event.latitude, longitude: event.longitude, locationName: getCityName())
            } else {
                WeatherViewForEvent(cityName: extractCityName())
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditEventView(event: event, onSave: { updatedEvent in
                event.title = updatedEvent.title
                event.date = updatedEvent.date
                event.category = updatedEvent.category
                event.locationName = updatedEvent.locationName
                event.details = updatedEvent.details
                event.imageData = updatedEvent.imageData
                event.latitude = updatedEvent.latitude
                event.longitude = updatedEvent.longitude
                try? modelContext.save()
                showEditSheet = false
            })
        }
    }
    
    // MARK: - Helper Methods
    func getVenueName() -> String? {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 3 && !parts[0].isEmpty { return parts[0] }
        return nil
    }
    
    func getCityName() -> String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 5 { return parts[2] }
        else if parts.count >= 3 { return parts[1] }
        return extractCityFromAddress()
    }
    
    func getAddress() -> String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        if parts.count >= 5 { return "\(parts[1]), \(parts[2]), \(parts[3]) \(parts[4])" }
        else if parts.count >= 3 { return parts[2] }
        return event.locationName
    }

    func extractCityName() -> String { return getCityName() }
    
    func extractCityFromAddress() -> String {
        let address = getAddress()
        if address.contains("Las Vegas") { return "Las Vegas" }
        return address
    }
    
    func openInWaze() {
        let address = getAddress().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if event.latitude != 0.0 && event.longitude != 0.0 {
            let wazeURL = "waze://?ll=\(event.latitude),\(event.longitude)&navigate=yes"
            if let url = URL(string: wazeURL), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        let wazeAddressURL = "waze://?q=\(address)&navigate=yes"
        if let url = URL(string: wazeAddressURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func openInAppleMaps() {
        let address = getAddress().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = (event.latitude != 0.0) ? "maps://?ll=\(event.latitude),\(event.longitude)&q=\(address)" : "maps://?q=\(address)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func openInGoogleMaps() {
        let address = getAddress().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let googleMapsURL = (event.latitude != 0.0) ? "comgooglemaps://?daddr=\(event.latitude),\(event.longitude)&directionsmode=driving" : "comgooglemaps://?q=\(address)"
        if let url = URL(string: googleMapsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
