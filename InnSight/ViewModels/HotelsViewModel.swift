//
//  HotelsViewModel.swift
//  InnSight
//
//  Created by Arturo Gutierrez on 11/02/26.
//


import Foundation
import Supabase
import Combine
import CoreLocation

@MainActor
class HotelsViewModel: ObservableObject {
    
    @Published var hotels: [Hotel] = []
    @Published var searchText: String = ""
    @Published var isSortedByProximity: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    
    var filteredHotels: [Hotel] {
        var result = hotels
        
        // Filter by city name (case-insensitive on location field)
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            result = result.filter { hotel in
                guard let location = hotel.location else { return false }
                return location.localizedCaseInsensitiveContains(trimmed)
            }
        }
        
        // Sort by proximity if enabled and user location is available
        if isSortedByProximity, let userLoc = userLocation {
            result.sort { a, b in
                let distA = distanceToHotel(a, from: userLoc)
                let distB = distanceToHotel(b, from: userLoc)
                switch (distA, distB) {
                case (.some(let dA), .some(let dB)):
                    return dA < dB
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return false
                }
            }
        }
        
        return result
    }
    
    /// Returns the distance in km from the given coordinate to the hotel, or nil if the hotel has no coordinates.
    func distanceToHotel(_ hotel: Hotel) -> Double? {
        guard let userLoc = userLocation else { return nil }
        return distanceToHotel(hotel, from: userLoc)
    }
    
    func fetchHotels() async {
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .execute()
                .value
            
            hotels = response
            print("✅ Hoteles obtenidos:", hotels.count)
            
        } catch {
            print("❌ Error fetching hotels:", error.localizedDescription)
        }
    }
    
    // MARK: - Private
    
    private func distanceToHotel(_ hotel: Hotel, from coordinate: CLLocationCoordinate2D) -> Double? {
        guard let lat = hotel.latitude, let lon = hotel.longitude else { return nil }
        return haversineDistance(lat1: coordinate.latitude, lon1: coordinate.longitude, lat2: lat, lon2: lon)
    }
}
