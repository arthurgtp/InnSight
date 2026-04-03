//
//  Hotel.swift
//  InnSight
//
//  Modelo de hotel mejorado con más funcionalidad
//

import Foundation

struct Hotel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let imageUrl: String?
    let description: String?
    let rating: Double?
    let amenities: [String]
    let ownerId: UUID
    let createdAt: Date
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Hotel, rhs: Hotel) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "hotel_id"
        case name
        case location
        case latitude
        case longitude
        case imageUrl = "image_url"
        case description
        case rating
        case amenities
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
    
    // MARK: - Computed Properties
    var ratingFormatted: String {
        guard let rating = rating else { return "Sin calificación" }
        return String(format: "%.1f", rating)
    }
    
    var ratingStars: String {
        guard let rating = rating else { return "" }
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        
        var stars = String(repeating: "★", count: fullStars)
        if hasHalfStar {
            stars += "½"
        }
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        stars += String(repeating: "☆", count: emptyStars)
        
        return stars
    }
    
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
    
    var shortLocation: String {
        guard let location = location else { return "Ubicación no disponible" }
        let components = location.components(separatedBy: ",")
        return components.prefix(2).joined(separator: ", ")
    }
}

// MARK: - Hotel Statistics
struct HotelStats: Codable {
    let hotelId: UUID
    let totalRooms: Int
    let availableRooms: Int
    let occupancyRate: Double
    let averagePrice: Decimal
    let totalReservations: Int
    let revenue: Decimal
    
    enum CodingKeys: String, CodingKey {
        case hotelId = "hotel_id"
        case totalRooms = "total_rooms"
        case availableRooms = "available_rooms"
        case occupancyRate = "occupancy_rate"
        case averagePrice = "average_price"
        case totalReservations = "total_reservations"
        case revenue
    }
    
    var occupancyPercentage: String {
        String(format: "%.1f%%", occupancyRate * 100)
    }
    
    var averagePriceFormatted: String {
        averagePrice.toCurrency()
    }
    
    var revenueFormatted: String {
        revenue.toCurrency()
    }
}
