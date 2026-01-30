//
//  EditEventView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/19/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    
    var event: Event
    var onSave: (Event) -> Void
    
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var venueName: String = ""
    @State private var streetAddress: String = ""
    @State private var cityName: String = ""
    @State private var stateName: String = ""
    @State private var zipCode: String = ""
    @State private var category: EventCategory = .community
    @State private var details: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // BRANDED HEADER
                headerSection
                
                ScrollView {
                    VStack(spacing: 25) {
                        flyerSection
                        formFields
                    }
                    .padding()
                }
                
                // SAVE BUTTON (No payment required)
                Button(action: { saveData() }) {
                    Text("SAVE CHANGES")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!title.isEmpty ? Color.yellow : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(title.isEmpty)
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadInitialData() }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    // ✅ COMPRESS IMAGE BEFORE STORING
                    selectedImageData = ImageCompressor.compress(uiImage, maxSizeKB: 500)
                }
            }
        }
    }

    // MARK: - Sub-Views

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.yellow)
                    .font(.title2.bold())
            }
            Spacer()
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 45))
                    .foregroundColor(.yellow)
                VStack(spacing: -1) {
                    Text("ON").font(.system(size: 7, weight: .black))
                    Text("THA").font(.system(size: 6, weight: .black))
                    Text("SET").font(.system(size: 9, weight: .black))
                }
                .foregroundColor(.black)
                .offset(y: -2)
            }
            Spacer()
            Image(systemName: "xmark").opacity(0)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
    }

    private var flyerSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    // ✅ SHOW ENTIRE FLYER WITH PROPER ASPECT FIT
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 150)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus").font(.title)
                                Text("CHANGE EVENT FLYER").font(.caption.bold())
                            }
                            .foregroundColor(.yellow)
                        )
                }
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 18) {
            fieldContainer(label: "EVENT TITLE") {
                TextField("Set Name", text: $title)
                    .modifier(FormTextFieldStyle())
            }
            
            fieldContainer(label: "EVENT DATE & TIME") {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            fieldContainer(label: "VENUE NAME") {
                TextField("e.g., The Hideout", text: $venueName)
                    .modifier(FormTextFieldStyle())
            }
            
            fieldContainer(label: "STREET ADDRESS") {
                TextField("e.g., 4211 Fossatello Ave", text: $streetAddress)
                    .modifier(FormTextFieldStyle())
            }
            
            HStack(spacing: 12) {
                fieldContainer(label: "CITY") {
                    TextField("Las Vegas", text: $cityName)
                        .modifier(FormTextFieldStyle())
                }
                
                fieldContainer(label: "STATE") {
                    TextField("NV", text: $stateName)
                        .modifier(FormTextFieldStyle())
                }
                .frame(width: 80)
            }
            
            fieldContainer(label: "ZIP CODE") {
                TextField("89084", text: $zipCode)
                    .modifier(FormTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            fieldContainer(label: "DETAILS") {
                TextField("Description", text: $details, axis: .vertical)
                    .lineLimit(3...5)
                    .modifier(FormTextFieldStyle())
            }
        }
    }

    private func fieldContainer<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
            content()
        }
    }

    // MARK: - Logic & Helpers
    
    func loadInitialData() {
        title = event.title
        date = event.date
        
        // Parse: "VenueName|CityName|FullAddress" or new format "VenueName|Street|City|State|ZIP"
        let parts = event.locationName.split(separator: "|").map { String($0) }
        
        if parts.count >= 5 {
            // New format: VenueName|Street|City|State|ZIP
            venueName = parts[0]
            streetAddress = parts[1]
            cityName = parts[2]
            stateName = parts[3]
            zipCode = parts[4]
        } else if parts.count == 3 {
            // Old format: VenueName|CityName|FullAddress
            venueName = parts[0]
            cityName = parts[1]
            // Try to parse full address
            let addressParts = parts[2].components(separatedBy: ",")
            if addressParts.count >= 2 {
                streetAddress = addressParts[0].trimmingCharacters(in: .whitespaces)
            }
        }
        
        category = event.category
        details = event.details
        selectedImageData = event.imageData
    }

    func saveData() {
        // Construct full address for geocoding
        let fullAddress = "\(streetAddress), \(cityName), \(stateName) \(zipCode)"
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(fullAddress) { placemarks, _ in
            let coordinate = placemarks?.first?.location?.coordinate
            
            // New storage format: VenueName|Street|City|State|ZIP (more precise!)
            let combinedLocation = "\(venueName)|\(streetAddress)|\(cityName)|\(stateName)|\(zipCode)"
            
            let updatedEvent = Event(
                title: title,
                date: date,
                category: category,
                locationName: combinedLocation,
                details: details,
                securityCode: event.securityCode,
                price: event.price,
                latitude: coordinate?.latitude ?? event.latitude,
                longitude: coordinate?.longitude ?? event.longitude
            )
            updatedEvent.imageData = selectedImageData
            
            onSave(updatedEvent)
        }
    }
}
