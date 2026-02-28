//
//  AdminNotification.swift
//  InnSight
//
//  Modelo de notificación para administradores
//

import Foundation
import SwiftUI

struct AdminNotification: Identifiable, Codable {
    let id: UUID
    let ownerId: UUID
    let type: NotificationType
    let title: String
    let message: String
    let relatedReservationId: UUID?
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "notification_id"
        case ownerId = "owner_id"
        case type
        case title
        case message
        case relatedReservationId = "related_reservation_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    // Init for previews and tests
    init(id: UUID, ownerId: UUID, type: NotificationType, title: String, message: String, relatedReservationId: UUID?, isRead: Bool, createdAt: Date) {
        self.id = id
        self.ownerId = ownerId
        self.type = type
        self.title = title
        self.message = message
        self.relatedReservationId = relatedReservationId
        self.isRead = isRead
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: createdAt)
    }
}

// MARK: - Notification Type
enum NotificationType: String, Codable, CaseIterable {
    case newReservation = "new_reservation"
    case cancellation = "cancellation"
    case checkIn = "check_in"
    case checkOut = "check_out"
    
    var displayName: String {
        switch self {
        case .newReservation: return "Nueva Reservación"
        case .cancellation: return "Cancelación"
        case .checkIn: return "Check-in"
        case .checkOut: return "Check-out"
        }
    }
    
    var icon: String {
        switch self {
        case .newReservation: return "calendar.badge.plus"
        case .cancellation: return "calendar.badge.minus"
        case .checkIn: return "key.horizontal"
        case .checkOut: return "door.left.hand.open"
        }
    }
    
    var color: Color {
        switch self {
        case .newReservation: return AppColors.success
        case .cancellation: return AppColors.error
        case .checkIn: return AppColors.info
        case .checkOut: return AppColors.secondary
        }
    }
}

// MARK: - New Notification Request (for creating notifications)
struct NewNotification: Encodable {
    let ownerId: UUID
    let type: NotificationType
    let title: String
    let message: String
    let relatedReservationId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case type
        case title
        case message
        case relatedReservationId = "related_reservation_id"
    }
}
