//
//  ReservationFilter.swift
//  InnSight
//
//  Filtro para reservaciones en el historial
//

import Foundation

enum ReservationFilter: String, CaseIterable {
    case all = "all"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .all: return "Todas"
        case .active: return "Activas"
        case .completed: return "Completadas"
        case .cancelled: return "Canceladas"
        }
    }
    
    func matches(_ reservation: Reservation) -> Bool {
        switch self {
        case .all: return true
        case .active: return reservation.isActive
        case .completed: return reservation.isCompleted
        case .cancelled: return reservation.isCancelled
        }
    }
}
