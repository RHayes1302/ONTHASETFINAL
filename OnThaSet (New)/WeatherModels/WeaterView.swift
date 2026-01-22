//
//  WeaterView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/16/26.
//

import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showManualSearch = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // BACKGROUND
                backgroundLayer

                // MAIN CONTENT
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        logoSection
                            .padding(.top, 60)

                        Text("Ride Forecast")
                            .font(.system(size: 48, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(radius: 5)

                        // GPS or Manual Search
                        if weatherViewModel.cityName.isEmpty {
                            if !weatherViewModel.isLoading {
                                // Show manual search option
                                VStack(spacing: 15) {
                                    Text("Can't detect location?")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    
                                    if showManualSearch {
                                        manualSearchSection
                                    } else {
                                        Button(action: { showManualSearch = true }) {
                                            Text("SEARCH MANUALLY")
                                                .font(.headline.bold())
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.yellow)
                                                .cornerRadius(10)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                gpsPrompt
                            }
                        }

                        if !weatherViewModel.rideSafetyMessage.isEmpty {
                            safetyBanner
                        }
                        
                        if !weatherViewModel.dailyForecasts.isEmpty {
                            currentWeatherCard
                            forecastList
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // BACK BUTTON (Always visible)
                Button {
                    weatherViewModel.reset()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.yellow)
                        .font(.title2.bold())
                }
                .padding(.leading, 25)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if weatherViewModel.isLoading {
                    loadingOverlay
                }
            }
            .task {
                handleLocationRequest()
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                if let location = newLocation, weatherViewModel.cityName.isEmpty {
                    Task {
                        await weatherViewModel.fetchWeatherByLocation(location)
                    }
                }
            }
        }
    }

    // MARK: - SUB-VIEWS
    
    private var manualSearchSection: some View {
        VStack(spacing: 12) {
            TextField("Enter city name", text: $weatherViewModel.searchText)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
            
            Button(action: {
                Task {
                    await weatherViewModel.searchWeather()
                }
            }) {
                Text("SEARCH")
                    .font(.headline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    private var backgroundLayer: some View {
        Color.black.ignoresSafeArea()
            .background {
                Image("Road")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.5))
                    .ignoresSafeArea()
            }
    }

    private var gpsPrompt: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text("Locating your set...")
                .foregroundStyle(.white.opacity(0.7))
                .font(.subheadline)
        }
        .padding(.top, 20)
    }

    private var currentWeatherCard: some View {
        VStack(spacing: 15) {
            Text("CURRENT CONDITIONS")
                .font(.caption.bold())
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                VStack(spacing: 5) {
                    Image(systemName: weatherViewModel.dailyForecasts.first?.iconName ?? "sun.max.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 50))
                    Text("NOW")
                        .font(.caption2.bold())
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let firstDay = weatherViewModel.dailyForecasts.first {
                        Text(firstDay.highTemp)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("High: \(firstDay.highTemp) • Low: \(firstDay.lowTemp)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .padding(.horizontal)
        }
    }

    private var forecastList: some View {
        VStack(spacing: 0) {
            ForEach(weatherViewModel.dailyForecasts) { day in
                HStack {
                    Text(day.day)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 75, alignment: .leading)
                        .foregroundStyle(.black)
                    Spacer()
                    Image(systemName: day.iconName)
                        .symbolRenderingMode(.multicolor)
                        .font(.title3)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(day.lowTemp).opacity(0.7)
                        Text("/")
                        Text(day.highTemp).bold()
                    }
                    .foregroundStyle(.black)
                    .frame(width: 90, alignment: .trailing)
                }
                .padding()
                .background(Color.white)
                
                if day.id != weatherViewModel.dailyForecasts.last?.id {
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
        }
        .cornerRadius(15)
        .padding(.horizontal)
    }

    private var logoSection: some View {
        ZStack {
            Image(systemName: "shield.fill").font(.system(size: 80)).foregroundColor(.yellow)
            VStack(spacing: -2) {
                Text("ON").font(.system(size: 12, weight: .black))
                Text("THA").font(.system(size: 10, weight: .black))
                Text("SET").font(.system(size: 15, weight: .black))
            }.foregroundColor(.black).offset(y: -4)
        }
    }

    private var safetyBanner: some View {
        HStack(spacing: 15) {
            safetyIconSmall
            VStack(alignment: .leading, spacing: 2) {
                Text(weatherViewModel.rideSafetyMessage).font(.headline).fontWeight(.black)
                Text(weatherViewModel.cityName.uppercased()).font(.caption2).tracking(2)
            }
            Spacer()
        }
        .padding()
        .background(weatherViewModel.rideSafetyColor.opacity(0.95))
        .cornerRadius(12)
        .foregroundStyle(.white)
        .padding(.horizontal)
    }
    
    private var safetyIconSmall: some View {
        ZStack {
            Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
            VStack(spacing: -1) {
                Text("ON").font(.system(size: 7, weight: .black))
                Text("THA").font(.system(size: 6, weight: .black))
                Text("SET").font(.system(size: 9, weight: .black))
            }.foregroundColor(.black).offset(y: -2)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 15) {
                ProgressView("ANALYZING...")
                    .tint(.yellow)
                    .foregroundStyle(.yellow)
                
                // Add timeout option
                Button("Search Manually Instead") {
                    weatherViewModel.isLoading = false
                    showManualSearch = true
                }
                .foregroundColor(.yellow)
                .font(.caption)
            }
        }
    }

    private func handleLocationRequest() {
        if let location = locationManager.userLocation {
            Task {
                await weatherViewModel.fetchWeatherByLocation(location)
            }
        } else {
            locationManager.requestLocation()
            // Auto-show manual search after 3 seconds if location fails
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if weatherViewModel.cityName.isEmpty && !weatherViewModel.isLoading {
                    showManualSearch = true
                }
            }
        }
    }
}
