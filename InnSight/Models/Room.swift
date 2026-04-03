//
//  Room.swift
//  InnSight
//
//  Modelo de habitación con soporte para imágenes y amenidades
//

import Foundation

struct Room: Identifiable, Codable, Hashable {
    let id: UUID
    let hotelId: UUID
    let roomNumber: String
    let roomType: RoomType
    let price: Decimal
    let capacity: Int
    let description: String?
    let amenities: [String]
    let images: [RoomImage]
    let isActive: Bool
    let createdAt: Date
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "room_id"
        case hotelId = "hotel_id"
        case roomNumber = "room_number"
        case roomType = "room_type"
        case price
        case capacity
        case description
        case amenities
        case images
        case isActive = "is_active"
        case createdAt = "created_at"
    }
    
    // MARK: - Computed Properties
    var priceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
    
    var mainImage: RoomImage? {
        images.first(where: { $0.isPrimary }) ?? images.first
    }
    
    var image360: RoomImage? {
        images.first(where: { $0.is360 })
    }
    
    var hasImage360: Bool {
        image360 != nil
    }
}

// MARK: - Room Type
enum RoomType: String, Codable, CaseIterable {
    case single = "single"
    case double = "double"
    case suite = "suite"
    case deluxe = "deluxe"
    case presidential = "presidential"
    
    var displayName: String {
        switch self {
        case .single: return "Individual"
        case .double: return "Doble"
        case .suite: return "Suite"
        case .deluxe: return "Deluxe"
        case .presidential: return "Presidencial"
        }
    }
    
    var icon: String {
        switch self {
        case .single: return "bed.double"
        case .double: return "bed.double.fill"
        case .suite: return "house"
        case .deluxe: return "house.fill"
        case .presidential: return "crown"
        }
    }
}

// MARK: - Room Image
struct RoomImage: Identifiable, Codable {
    let id: UUID
    let roomId: UUID
    let url: String
    let isPrimary: Bool
    let is360: Bool
    let caption: String?
    let order: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "image_id"
        case roomId = "room_id"
        case url = "image_url"
        case isPrimary = "is_primary"
        case is360 = "is_360"
        case caption
        case order = "display_order"
    }
}

// MARK: - Amenities
struct Amenity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: AmenityCategory
}

enum AmenityCategory: String {
    case comfort = "Comodidad"
    case technology = "Tecnología"
    case bathroom = "Baño"
    case entertainment = "Entretenimiento"
    case service = "Servicio"
}

// MARK: - Common Amenities
extension Amenity {
    static let commonAmenities: [Amenity] = [
        Amenity(name: "WiFi", icon: "wifi", category: .technology),
        Amenity(name: "TV", icon: "tv", category: .entertainment),
        Amenity(name: "Aire Acondicionado", icon: "snowflake", category: .comfort),
        Amenity(name: "Minibar", icon: "refrigerator", category: .comfort),
        Amenity(name: "Caja Fuerte", icon: "lock.shield", category: .service),
        Amenity(name: "Room Service", icon: "bell.badge", category: .service),
        Amenity(name: "Secadora de Pelo", icon: "wind", category: .bathroom),
        Amenity(name: "Plancha", icon: "iron", category: .comfort),
        Amenity(name: "Teléfono", icon: "phone", category: .technology),
        Amenity(name: "Escritorio", icon: "desk", category: .comfort),
        Amenity(name: "Balcón", icon: "building.2", category: .comfort),
        Amenity(name: "Vista al Mar", icon: "water.waves", category: .entertainment)
    ]
    
    static func fromString(_ name: String) -> Amenity? {
        commonAmenities.first { $0.name.lowercased() == name.lowercased() }
    }
}
