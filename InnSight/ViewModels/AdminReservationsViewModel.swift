//
//  AdminReservationsViewModel.swift
//  InnSight
//
//  ViewModel para gestión de reservaciones del administrador
//

import Foundation
import Combine
import Supabase

@MainActor
class AdminReservationsViewModel: ObservableObject {
    @Published var reservations: [AdminReservation] = []
    @Published var filteredReservations: [AdminReservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filters
    @Published var statusFilter: ReservationStatus? {
        didSet { applyFilters() }
    }
    @Published var hotelFilter: Hotel? {
        didSet { applyFilters() }
    }
    @Published var startDateFilter: Date? {
        didSet { applyFilters() }
    }
    @Published var endDateFilter: Date? {
        didSet { applyFilters() }
    }
    
    var hasActiveFilters: Bool {
        statusFilter != nil || hotelFilter != nil || startDateFilter != nil || endDateFilter != nil
    }
    
    // MARK: - Fetch Reservations
    
    func fetchReservations(for ownerId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched: [AdminReservation] = try await supabase
                .from("admin_reservations_view")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let ownerHotels: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .execute()
                .value
            
            let ownerHotelIds = Set(ownerHotels.map { $0.id })
            reservations = fetched.filter { ownerHotelIds.contains($0.hotelId) }
            applyFilters()
            
        } catch is CancellationError {
            print("⚠️ Reservations fetch was cancelled")
            // Don't show error for cancellation
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            print("⚠️ Reservations fetch was cancelled (URL)")
            // Don't show error for URL cancellation
        } catch {
            errorMessage = "Error al cargar reservaciones: \(error.localizedDescription)"
            print("❌ Error fetching admin reservations:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Apply Filters
    
    func applyFilters() {
        var result = reservations
        
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        
        if let hotel = hotelFilter {
            result = result.filter { $0.hotelId == hotel.id }
        }
        
        if let start = startDateFilter {
            result = result.filter { $0.endDate >= start }
        }
        
        if let end = endDateFilter {
            result = result.filter { $0.startDate <= end }
        }
        
        filteredReservations = result
    }
    
    // MARK: - Reset Filters
    
    func resetFilters() {
        statusFilter = nil
        hotelFilter = nil
        startDateFilter = nil
        endDateFilter = nil
    }
    
    // MARK: - Update Reservation Status
    
    func updateReservationStatus(_ reservationId: UUID, status: ReservationStatus) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("reservations")
                .update(["status": status.rawValue])
                .eq("reservation_id", value: reservationId.uuidString)
                .execute()
            
            // Update local state
            if let index = reservations.firstIndex(where: { $0.id == reservationId }) {
                let old = reservations[index]
                reservations[index] = AdminReservation(
                    id: old.id, roomId: old.roomId, clientId: old.clientId,
                    hotelId: old.hotelId, hotelName: old.hotelName,
                    roomNumber: old.roomNumber, roomType: old.roomType,
                    clientName: old.clientName, clientEmail: old.clientEmail,
                    startDate: old.startDate, endDate: old.endDate,
                    status: status, totalPrice: old.totalPrice,
                    guestCount: old.guestCount, specialRequests: old.specialRequests,
                    createdAt: old.createdAt
                )
            }
            applyFilters()
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al actualizar estado: \(error.localizedDescription)"
            print("❌ Error updating reservation status:", error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Valid Status Transitions
    
    static func validNextStatuses(for current: ReservationStatus) -> [ReservationStatus] {
        switch current {
        case .confirmed:
            return [.checkedIn, .cancelled]
        case .checkedIn:
            return [.checkedOut]
        case .checkedOut:
            return [.completed]
        default:
            return []
        }
    }
}
