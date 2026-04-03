//
//  Reservation.swift
//  InnSight
//
//  Modelo de reservación
//

import Foundation

struct Reservation: Identifiable, Codable {
    let id: UUID
    let roomId: UUID
    let clientId: UUID
    let hotelName: String?
    let roomNumber: String?
    let roomType: String?
    let startDate: Date
    let endDate: Date
    let status: ReservationStatus
    let totalPrice: Decimal
    let guestCount: Int?
    let specialRequests: String?
    let checkInTime: Date?
    let checkOutTime: Date?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "reservation_id"
        case roomId = "room_id"
        case clientId = "client_id"
        case hotelName = "hotel_name"
        case roomNumber = "room_number"
        case roomType = "room_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case totalPrice = "total_price"
        case guestCount = "guest_count"
        case specialRequests = "special_requests"
        case checkInTime = "check_in_time"
        case checkOutTime = "check_out_time"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        roomId = try container.decode(UUID.self, forKey: .roomId)
        clientId = try container.decode(UUID.self, forKey: .clientId)
        hotelName = try container.decodeIfPresent(String.self, forKey: .hotelName)
        roomNumber = try container.decodeIfPresent(String.self, forKey: .roomNumber)
        roomType = try container.decodeIfPresent(String.self, forKey: .roomType)
        status = try container.decode(ReservationStatus.self, forKey: .status)
        totalPrice = try container.decode(Decimal.self, forKey: .totalPrice)
        guestCount = try container.decodeIfPresent(Int.self, forKey: .guestCount)
        specialRequests = try container.decodeIfPresent(String.self, forKey: .specialRequests)
        checkInTime = try container.decodeIfPresent(Date.self, forKey: .checkInTime)
        checkOutTime = try container.decodeIfPresent(Date.self, forKey: .checkOutTime)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        
        // Decodificar fechas que pueden venir como "yyyy-MM-dd"
        startDate = try Self.decodeFlexibleDate(from: container, forKey: .startDate)
        endDate = try Self.decodeFlexibleDate(from: container, forKey: .endDate)
    }
    
    private static func decodeFlexibleDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Intentar decodificar como Date primero (ISO8601)
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // Si falla, intentar como String con formato yyyy-MM-dd
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
    
    // Init para previews y tests
    init(id: UUID, roomId: UUID, clientId: UUID, hotelName: String?, roomNumber: String?, roomType: String?, startDate: Date, endDate: Date, status: ReservationStatus, totalPrice: Decimal, guestCount: Int?, specialRequests: String?, checkInTime: Date?, checkOutTime: Date?, createdAt: Date?) {
        self.id = id
        self.roomId = roomId
        self.clientId = clientId
        self.hotelName = hotelName
        self.roomNumber = roomNumber
        self.roomType = roomType
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.totalPrice = totalPrice
        self.guestCount = guestCount
        self.specialRequests = specialRequests
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    var nights: Int {
        startDate.daysBetween(endDate)
    }
    
    var isActive: Bool {
        // Active if confirmed and start date hasn't passed yet
        (status == .confirmed) && startDate >= Date().startOfDay
    }
    
    var isCompleted: Bool {
        status == .completed || (status == .checkedOut) || (status != .cancelled && endDate.isPast())
    }
    
    var isCancelled: Bool {
        status == .cancelled
    }
    
    var canBeCancelled: Bool {
        // Can cancel if confirmed and start date is today or in the future
        status == .confirmed && startDate >= Date().startOfDay
    }
    
    var totalPriceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: totalPrice as NSDecimalNumber) ?? "$0.00"
    }
    
    var dateRangeFormatted: String {
        "\(startDate.formattedShort()) - \(endDate.formattedShort())"
    }
    
    var nightsText: String {
        nights == 1 ? "1 noche" : "\(nights) noches"
    }
}

// MARK: - Reservation Status
enum ReservationStatus: String, Codable, CaseIterable {
    case confirmed = "confirmed"
    case checkedIn = "checked_in"
    case checkedOut = "checked_out"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no_show"
    
    var displayName: String {
        switch self {
        case .confirmed: return "Confirmada"
        case .checkedIn: return "Check-in"
        case .checkedOut: return "Check-out"
        case .completed: return "Completada"
        case .cancelled: return "Cancelada"
        case .noShow: return "No Show"
        }
    }
    
    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle"
        case .checkedIn: return "key.horizontal"
        case .checkedOut: return "door.left.hand.open"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .noShow: return "exclamationmark.triangle"
        }
    }
    
    var color: String {
        switch self {
        case .confirmed: return "4CAF50"
        case .checkedIn: return "2196F3"
        case .checkedOut: return "9C27B0"
        case .completed: return "4CAF50"
        case .cancelled: return "F44336"
        case .noShow: return "F44336"
        }
    }
}

// MARK: - Reservation Request (para crear nuevas reservaciones)
struct ReservationRequest: Codable {
    let roomId: UUID
    let clientId: UUID
    let startDate: Date
    let endDate: Date
    let totalPrice: Decimal
    let guestCount: Int
    let specialRequests: String?
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case clientId = "client_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalPrice = "total_price"
        case guestCount = "guest_count"
        case specialRequests = "special_requests"
    }
    
    var nights: Int {
        startDate.daysBetween(endDate)
    }
}
