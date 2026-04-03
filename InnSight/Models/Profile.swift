//
//  Profile.swift
//  InnSight
//
//  Modelo de perfil de usuario
//

import Foundation

struct Profile: Identifiable, Codable {
    let id: UUID
    let fullName: String
    let email: String?
    let role: UserRole
    let phoneNumber: String?
    let dateOfBirth: Date?
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case fullName = "full_name"
        case email
        case role
        case phoneNumber = "phone_number"
        case dateOfBirth = "date_of_birth"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    var isAdmin: Bool {
        role == .admin
    }
    
    var isClient: Bool {
        role == .client
    }
}

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case client = "client"
    
    var displayName: String {
        switch self {
        case .admin: return "Administrador"
        case .client: return "Cliente"
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "person.badge.shield.checkmark"
        case .client: return "person.circle"
        }
    }
    
    var color: String {
        switch self {
        case .admin: return "FFC107"
        case .client: return "00BCD4"
        }
    }
}

// MARK: - Profile Stats (para dashboard)
struct ProfileStats: Codable {
    let totalReservations: Int
    let activeReservations: Int
    let completedReservations: Int
    let cancelledReservations: Int
    let totalSpent: Decimal
    
    enum CodingKeys: String, CodingKey {
        case totalReservations = "total_reservations"
        case activeReservations = "active_reservations"
        case completedReservations = "completed_reservations"
        case cancelledReservations = "cancelled_reservations"
        case totalSpent = "total_spent"
    }
    
    var totalSpentFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0.00"
    }
}
