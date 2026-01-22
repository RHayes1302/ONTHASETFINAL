//
//  WeatherViewForEvent.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/18/26.
//

import SwiftUI

// Weather View that automatically searches for a city on load
struct WeatherViewForEvent: View {
    let cityName: String
    @StateObject private var weatherViewModel = WeatherViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // BACKGROUND
            Color.clear
                .background {
                    ZStack {
                        Image("Road")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Color.black.opacity(0.5)
                    }
                    .ignoresSafeArea()
                }
                .allowsHitTesting(false)

            // MAIN CONTENT
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    
                    // LOGO
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 80)).foregroundColor(.yellow)
                        VStack(spacing: -2) {
                            Text("ON").font(.system(size: 12, weight: .black))
                            Text("THA").font(.system(size: 10, weight: .black))
                            Text("SET").font(.system(size: 15, weight: .black))
                        }.foregroundColor(.black).offset(y: -4)
                    }
                    .padding(.top, 60)

                    // TITLE
                    Text("Ride Forecast")
                        .font(.system(size: 48, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                        .shadow(radius: 5)
                    
                    // CITY NAME
                    Text(weatherViewModel.cityName.isEmpty ? "Loading \(cityName)..." : weatherViewModel.cityName.uppercased())
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                    
                    // DEBUG: Show if loading failed
                    if weatherViewModel.cityName.isEmpty && !weatherViewModel.isLoading {
                        Text("Unable to load weather for \(cityName)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // RIDE SAFETY BANNER
                    if !weatherViewModel.rideSafetyMessage.isEmpty {
                        HStack(spacing: 15) {
                            ZStack {
                                Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 7, weight: .black))
                                    Text("THA").font(.system(size: 6, weight: .black))
                                    Text("SET").font(.system(size: 9, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            }
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
                    
                    // CURRENT CONDITIONS
                    if !weatherViewModel.cityName.isEmpty && !weatherViewModel.dailyForecasts.isEmpty {
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

                    // 7-DAY OUTLOOK
                    if !weatherViewModel.dailyForecasts.isEmpty {
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
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    }
                }
                .padding(.bottom, 40)
            }
            
            // BACK BUTTON
            if !weatherViewModel.cityName.isEmpty {
                Button {
                    weatherViewModel.reset()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .fontWeight(.bold).foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.black.opacity(0.7)).clipShape(Capsule())
                }
                .padding(.leading, 20).padding(.top, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if weatherViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ProgressView("ANALYZING...").tint(.yellow).foregroundStyle(.yellow)
                }
            }
        }
        .onAppear {
            // Automatically search for weather when view appears
            weatherViewModel.searchText = cityName
            Task {
                await weatherViewModel.searchWeather()
            }
        }
    }
}
