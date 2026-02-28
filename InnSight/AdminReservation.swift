//
//  AdminReservation.swift
//  InnSight
//
//  Modelo de reservación extendido para vista de administrador
//

import Foundation

struct AdminReservation: Identifiable, Codable {
    let id: UUID
    let roomId: UUID
    let clientId: UUID
    let hotelId: UUID
    let hotelName: String
    let roomNumber: String
    let roomType: String
    let clientName: String
    let clientEmail: String?
    let startDate: Date
    let endDate: Date
    let status: ReservationStatus
    let totalPrice: Decimal
    let guestCount: Int?
    let specialRequests: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "reservation_id"
        case roomId = "room_id"
        case clientId = "client_id"
        case hotelId = "hotel_id"
        case hotelName = "hotel_name"
        case roomNumber = "room_number"
        case roomType = "room_type"
        case clientName = "client_name"
        case clientEmail = "client_email"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case totalPrice = "total_price"
        case guestCount = "guest_count"
        case specialRequests = "special_requests"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        roomId = try container.decode(UUID.self, forKey: .roomId)
        clientId = try container.decode(UUID.self, forKey: .clientId)
        hotelId = try container.decode(UUID.self, forKey: .hotelId)
        hotelName = try container.decode(String.self, forKey: .hotelName)
        roomNumber = try container.decode(String.self, forKey: .roomNumber)
        roomType = try container.decode(String.self, forKey: .roomType)
        clientName = try container.decode(String.self, forKey: .clientName)
        clientEmail = try container.decodeIfPresent(String.self, forKey: .clientEmail)
        status = try container.decode(ReservationStatus.self, forKey: .status)
        totalPrice = try container.decode(Decimal.self, forKey: .totalPrice)
        guestCount = try container.decodeIfPresent(Int.self, forKey: .guestCount)
        specialRequests = try container.decodeIfPresent(String.self, forKey: .specialRequests)
        createdAt = try Self.decodeFlexibleDate(from: container, forKey: .createdAt)
        
        // Decode dates that may come as "yyyy-MM-dd"
        startDate = try Self.decodeFlexibleDate(from: container, forKey: .startDate)
        endDate = try Self.decodeFlexibleDate(from: container, forKey: .endDate)
    }
    
    private static func decodeFlexibleDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Try to decode as Date first (ISO8601)
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // If that fails, try as String with yyyy-MM-dd format
        let dateString = try container.decode(String.self, forKey: key)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [key], debugDescription: "Invalid date format: \(dateString)")
        )
    }
    
    // Init for previews and tests
    init(id: UUID, roomId: UUID, clientId: UUID, hotelId: UUID, hotelName: String, roomNumber: String, roomType: String, clientName: String, clientEmail: String?, startDate: Date, endDate: Date, status: ReservationStatus, totalPrice: Decimal, guestCount: Int?, specialRequests: String?, createdAt: Date) {
        self.id = id
        self.roomId = roomId
        self.clientId = clientId
        self.hotelId = hotelId
        self.hotelName = hotelName
        self.roomNumber = roomNumber
        self.roomType = roomType
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.totalPrice = totalPrice
        self.guestCount = guestCount
        self.specialRequests = specialRequests
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    var nights: Int {
        startDate.daysBetween(endDate)
    }
    
    var totalPriceFormatted: String {
        totalPrice.toCurrency()
    }
    
    var dateRangeFormatted: String {
        "\(startDate.formattedShort()) - \(endDate.formattedShort())"
    }
    
    var nightsText: String {
        nights == 1 ? "1 noche" : "\(nights) noches"
    }
    
    var guestCountText: String {
        guard let count = guestCount else { return "1 huésped" }
        return count == 1 ? "1 huésped" : "\(count) huéspedes"
    }
    
    var roomTypeDisplayName: String {
        RoomType(rawValue: roomType)?.displayName ?? roomType.capitalized
    }
}
