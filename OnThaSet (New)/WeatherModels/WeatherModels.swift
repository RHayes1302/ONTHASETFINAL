//
//  WeatherModels.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 1/16/26.
//

import Foundation

// Response from Open-Meteo weather API
struct ForecastResponse: Codable {
    let current_weather: CurrentWeather
    let daily: DailyForecast
    
    struct CurrentWeather: Codable {
        let temperature: Double
        let windspeed: Double
        let weathercode: Int
    }
    
    struct DailyForecast: Codable {
        let time: [String]
        let weathercode: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}

// Response from geocoding API to convert city name to coordinates
struct GeocodingResponse: Codable {
    let results: [Location]?
    
    struct Location: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
}

// Model for displaying each day in the 7-day forecast
struct DayForecast: Identifiable {
    let id = UUID()
    let day: String
    let highTemp: String
    let lowTemp: String
    let iconName: String
}
