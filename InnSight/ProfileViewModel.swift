//
//  ProfileViewModel.swift
//  InnSight
//
//  ViewModel para gestionar el perfil de usuario y sus reservaciones
//

import Foundation
import Combine
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: ReservationFilter = .all
    
    // MARK: - Computed Properties
    
    var stats: ProfileStats {
        let total = reservations.count
        let active = reservations.filter { $0.isActive }.count
        let completed = reservations.filter { $0.isCompleted }.count
        let cancelled = reservations.filter { $0.isCancelled }.count
        let totalSpent = reservations
            .filter { $0.status == .completed }
            .reduce(Decimal.zero) { $0 + $1.totalPrice }
        
        return ProfileStats(
            totalReservations: total,
            activeReservations: active,
            completedReservations: completed,
            cancelledReservations: cancelled,
            totalSpent: totalSpent
        )
    }
    
    var filteredReservations: [Reservation] {
        reservations
            .filter { selectedFilter.matches($0) }
            .sorted { $0.startDate > $1.startDate }
    }
    
    // MARK: - Public Methods
    
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let fetchedProfile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            profile = fetchedProfile
        } catch {
            errorMessage = "Error al cargar el perfil: \(error.localizedDescription)"
            print("❌ Error fetching profile:", error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func fetchReservations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let fetchedReservations: [Reservation] = try await supabase
                .from("reservations")
                .select()
                .eq("client_id", value: userId.uuidString)
                .order("start_date", ascending: false)
                .execute()
                .value
            
            reservations = fetchedReservations
            print("📋 Reservaciones cargadas: \(reservations.count)")
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMessage = "Campo faltante: \(key.stringValue)"
                print("❌ Key not found: \(key.stringValue), context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                errorMessage = "Tipo incorrecto en los datos"
                print("❌ Type mismatch: expected \(type), path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                errorMessage = "Valor nulo inesperado"
                print("❌ Value not found: \(type), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .dataCorrupted(let context):
                errorMessage = "Datos corruptos"
                print("❌ Data corrupted: \(context.debugDescription)")
            @unknown default:
                errorMessage = "Error de decodificación"
                print("❌ Unknown decoding error: \(decodingError)")
            }
        } catch {
            errorMessage = "Error al cargar las reservaciones: \(error.localizedDescription)"
            print("❌ Error fetching reservations:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Cancel Reservation
    
    func cancelReservation(_ reservationId: String) async -> Bool {
        print("🔄 Cancelando reservación: \(reservationId)")
        
        do {
            try await supabase
                .from("reservations")
                .update(["status": "cancelled"])
                .eq("reservation_id", value: reservationId)
                .execute()
            
            print("✅ Reservación cancelada exitosamente")
            
            // Recargar reservaciones
            await fetchReservations()
            
            return true
        } catch {
            errorMessage = "Error al cancelar: \(error.localizedDescription)"
            print("❌ Error al cancelar:", error)
            return false
        }
    }
}
