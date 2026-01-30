//
//  WeatherViewModels.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/16/26.
//


import SwiftUI
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var cityName: String = ""
    @Published var dailyForecasts: [DayForecast] = []
    @Published var isLoading: Bool = false
    @Published var rideSafetyMessage: String = ""
    @Published var rideSafetyColor: Color = .green
    @Published var errorMessage: String = ""

    func searchWeather() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            print("❌ Search query is empty")
            return
        }
        
        print("🔍 Searching weather for: '\(query)'")
        self.isLoading = true
        self.errorMessage = ""
        
        let encodedCity = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let geocodingURL = "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1"
        
        print("🌐 Geocoding URL: \(geocodingURL)")
        
        do {
            guard let gUrl = URL(string: geocodingURL) else {
                print("❌ Invalid geocoding URL")
                self.isLoading = false
                return
            }
            
            let (gData, _) = try await URLSession.shared.data(from: gUrl)
            print("✅ Geocoding response received")
            
            let gResult = try JSONDecoder().decode(GeocodingResponse.self, from: gData)
            
            if let location = gResult.results?.first {
                print("📍 Found location: \(location.name) at \(location.latitude), \(location.longitude)")
                
                let weatherURL = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto&temperature_unit=fahrenheit&windspeed_unit=mph"
                
                print("🌐 Weather URL: \(weatherURL)")
                
                guard let wUrl = URL(string: weatherURL) else {
                    print("❌ Invalid weather URL")
                    self.isLoading = false
                    return
                }
                
                let (wData, _) = try await URLSession.shared.data(from: wUrl)
                print("✅ Weather response received")
                
                let wResult = try JSONDecoder().decode(ForecastResponse.self, from: wData)
                print("✅ Weather decoded successfully")
                
                self.parseWeather(wResult, name: location.name)
                print("✅ Weather parsed and displayed")
            } else {
                print("❌ No location found for: \(query)")
                self.errorMessage = "Location not found"
            }
        } catch {
            print("❌ Weather error: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            self.errorMessage = "Failed to load weather"
        }
        
        self.isLoading = false
        print("🏁 Search complete. City: '\(self.cityName)', Forecasts: \(self.dailyForecasts.count)")
    }

    private func parseWeather(_ result: ForecastResponse, name: String) {
        self.cityName = name
        let current = result.current_weather
        
        print("🌡️ Current temp: \(current.temperature)°F, Wind: \(current.windspeed) mph")
        
        // Ride Safety Logic
        if current.windspeed > 20 {
            rideSafetyMessage = "DANGEROUS WINDS: HIGH RISK"
            rideSafetyColor = .red
        } else if current.windspeed > 12 {
            rideSafetyMessage = "CAUTION: STICKY CONDITIONS"
            rideSafetyColor = .yellow
        } else {
            rideSafetyMessage = "CLEAR TO RIDE: OPTIMAL"
            rideSafetyColor = .green
        }

        var forecasts: [DayForecast] = []
        for i in 0..<result.daily.time.count {
            forecasts.append(DayForecast(
                day: i == 0 ? "TODAY" : formatDate(result.daily.time[i]),
                highTemp: "\(Int(result.daily.temperature_2m_max[i]))°F",
                lowTemp: "\(Int(result.daily.temperature_2m_min[i]))°F",
                iconName: mapWeatherCode(result.daily.weathercode[i])
            ))
        }
        self.dailyForecasts = forecasts
        print("📊 Created \(forecasts.count) daily forecasts")
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func mapWeatherCode(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...77: return "cloud.rain.fill"
        case 80...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    func reset() {
        cityName = ""
        searchText = ""
        dailyForecasts = []
        rideSafetyMessage = ""
        rideSafetyColor = .green
        errorMessage = ""
    }
    
    func searchWeatherByCoordinates(latitude: Double, longitude: Double, locationName: String) async {
        print("🎯 Searching weather by GPS: \(latitude), \(longitude)")
        self.isLoading = true
        self.errorMessage = ""
        self.cityName = locationName
        
        let weatherURL = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto&temperature_unit=fahrenheit&windspeed_unit=mph"
        
        do {
            guard let wUrl = URL(string: weatherURL) else {
                self.isLoading = false
                return
            }
            let (wData, _) = try await URLSession.shared.data(from: wUrl)
            let wResult = try JSONDecoder().decode(ForecastResponse.self, from: wData)
            self.parseWeather(wResult, name: locationName)
        } catch {
            print("❌ Weather error: \(error.localizedDescription)")
            self.errorMessage = "Failed to load weather"
        }
        
        self.isLoading = false
    }
    
    func fetchWeatherByLocation(_ location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let cityName = placemarks.first?.locality ?? "Your Location"
            await searchWeatherByCoordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: cityName
            )
        } catch {
            await searchWeatherByCoordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: "Your Location"
            )
        }
    }
}
