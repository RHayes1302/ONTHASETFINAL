//
//  LocationManager.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/7/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        print("✅ Location updated: \(locations.last?.coordinate.latitude ?? 0), \(locations.last?.coordinate.longitude ?? 0)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("📍 Authorization status: \(manager.authorizationStatus.rawValue)")
        
        // Auto-request location when authorized
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
    
    // FIXED: Only return events that are actually nearby
    // Changed default radius to 50 miles and fixed the logic
    func isNearby(event: Event, radiusInMiles: Double = 50) -> Bool {
        // If we don't have user location, DON'T show the event
        guard let userLoc = userLocation else {
            print("⚠️ No user location available")
            return false  // Changed from true to false
        }
        
        // If event doesn't have coordinates, DON'T show it
        guard event.latitude != 0.0 && event.longitude != 0.0 else {
            print("⚠️ Event '\(event.title)' has no coordinates")
            return false  // Changed from true to false
        }
        
        let eventLoc = CLLocation(latitude: event.latitude, longitude: event.longitude)
        let distanceInMeters = userLoc.distance(from: eventLoc)
        
        // Convert meters to miles
        let distanceInMiles = distanceInMeters / 1609.34
        
        print("📏 Event '\(event.title)' is \(String(format: "%.1f", distanceInMiles)) miles away")
        
        return distanceInMiles <= radiusInMiles
    }
}
