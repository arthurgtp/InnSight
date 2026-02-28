//
//  RoomsViewModel.swift
//  InnSight
//
//  ViewModel para gestionar la obtención y estado de habitaciones de un hotel
//

import Foundation
import Supabase
import Combine

@MainActor
class RoomsViewModel: ObservableObject {
    
    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let hotelId: UUID
    
    init(hotelId: UUID) {
        self.hotelId = hotelId
    }
    
    /// Obtiene las habitaciones activas del hotel desde Supabase
    func fetchRooms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [Room] = try await supabase
                .from("rooms")
                .select("*, images:room_images(*)")
                .eq("hotel_id", value: hotelId.uuidString)
                .eq("is_active", value: true)
                .order("room_type")
                .order("room_number")
                .execute()
                .value
            
            rooms = response
            print("✅ Habitaciones obtenidas:", rooms.count)
            
        } catch {
            errorMessage = "Error al cargar las habitaciones. Por favor, intenta de nuevo."
            print("❌ Error fetching rooms:", error.localizedDescription)
        }
        
        isLoading = false
    }
}
