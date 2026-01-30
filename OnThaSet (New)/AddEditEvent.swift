//
//  AddEditEvent.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//


import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var eventToEdit: Event
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
    @State private var securityCode: String = ""
    @State private var price: String = "3.00"
    @State private var showPaymentAlert = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    // Computed property to check if form is valid
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !securityCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
                        planSelectionSection
                        paymentButtonsSection
                    }
                    .padding()
                }
                
                submitButtonSection
            }
        }
        .navigationBarHidden(true)
        .alert("Confirm Payment", isPresented: $showPaymentAlert) {
            Button("I HAVE PAID") { saveData() }
            Button("CANCEL", role: .cancel) { }
        } message: {
            Text("Confirm payment has been sent. Your post will be verified by the admin.")
        }
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
                                Text("ADD EVENT FLYER").font(.caption.bold())
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

    private var planSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT PLAN").font(.caption2.bold()).foregroundColor(.yellow)
            HStack(spacing: 12) {
                planBtn(label: "SINGLE POST", val: "3.00")
                planBtn(label: "UNLIMITED MONTH", val: "10.00")
            }
        }
    }

    private func planBtn(label: String, val: String) -> some View {
        Button(action: { price = val }) {
            VStack {
                Text(label).font(.system(size: 8, weight: .black))
                Text("$\(val)").font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(price == val ? Color.yellow : Color.white.opacity(0.1))
            .foregroundColor(price == val ? .black : .white)
            .cornerRadius(10)
        }
    }

    private var paymentButtonsSection: some View {
        VStack(spacing: 15) {
            Text("PAYMENT METHOD").font(.caption2.bold()).foregroundColor(.yellow).frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                Button(action: { showPaymentAlert = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16))
                        Text("Pay")
                            .font(.system(size: 19, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                
                payBtn(label: "Venmo", color: Color(red: 0, green: 0.5, blue: 1)) { openURL("https://venmo.com/") }
                payBtn(label: "Cash App", color: .green) { openURL("https://cash.app/") }
            }
            fieldContainer(label: "SECURITY PIN (REQUIRED)") {
                TextField("4-digit pin", text: $securityCode)
                    .modifier(FormTextFieldStyle())
                    .keyboardType(.numberPad)
            }
        }
    }

    private func payBtn(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private var submitButtonSection: some View {
        Button(action: {
            print("Button tapped - Title: '\(title)', Code: '\(securityCode)'")
            showPaymentAlert = true
        }) {
            Text("CONFIRM & POST")
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.yellow : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
        .padding()
    }

    private func fieldContainer<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption2.bold()).foregroundColor(.yellow).padding(.leading, 5)
            content()
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) { UIApplication.shared.open(url) }
    }

    // MARK: - Logic & Helpers
    
    func loadInitialData() {
        if !eventToEdit.title.isEmpty {
            title = eventToEdit.title
            date = eventToEdit.date
            
            // Parse: "VenueName|Street|City|State|ZIP" (new format)
            let parts = eventToEdit.locationName.split(separator: "|").map { String($0) }
            
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
                // Try to parse the full address if possible
                let addressParts = parts[2].components(separatedBy: ",")
                if addressParts.count >= 2 {
                    streetAddress = addressParts[0].trimmingCharacters(in: .whitespaces)
                }
            } else if parts.count == 2 {
                // Very old format: VenueName|Address
                venueName = parts[0]
                streetAddress = parts[1]
            }
            
            category = eventToEdit.category
            details = eventToEdit.details
            securityCode = eventToEdit.securityCode
            selectedImageData = eventToEdit.imageData
            price = eventToEdit.price
        }
    }

    func saveData() {
        // Construct full address for geocoding
        let fullAddress = "\(streetAddress), \(cityName), \(stateName) \(zipCode)"
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(fullAddress) { placemarks, _ in
            let coordinate = placemarks?.first?.location?.coordinate
            
            // Storage format: VenueName|Street|City|State|ZIP
            let combinedLocation = "\(venueName)|\(streetAddress)|\(cityName)|\(stateName)|\(zipCode)"
            
            let finalEvent = Event(
                title: title, date: date, category: category,
                locationName: combinedLocation, details: details,
                securityCode: securityCode, price: price,
                latitude: coordinate?.latitude ?? 0.0,
                longitude: coordinate?.longitude ?? 0.0
            )
            finalEvent.imageData = selectedImageData
            onSave(finalEvent)
            dismiss()
        }
    }
}

// Global View Modifier
struct FormTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.padding().background(Color.white.opacity(0.1)).cornerRadius(8).foregroundColor(.white)
    }
}
