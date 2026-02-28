//
//  AdminViewModel.swift
//  InnSight
//
//  ViewModel para el panel de administración
//

import Foundation
import Supabase
import Combine

@MainActor
class AdminViewModel: ObservableObject {
    @Published var hotels: [Hotel] = []
    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalRooms = 0
    @Published var totalReservations = 0
    
    // MARK: - Fetch Hotels
    
    func fetchHotels() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation
            try Task.checkCancellation()
            
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let fetchedHotels: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("owner_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            hotels = fetchedHotels
            print("✅ Hoteles del admin: \(hotels.count)")
            
            // Fetch stats
            await fetchStats()
            
        } catch is CancellationError {
            // Task was cancelled, don't show error to user
            print("⚠️ Hotels fetch was cancelled")
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // URL request was cancelled, don't show error to user
            print("⚠️ Hotels fetch was cancelled (URL)")
        } catch {
            errorMessage = "Error al cargar hoteles: \(error.localizedDescription)"
            print("❌ Error fetching admin hotels:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Stats
    
    private func fetchStats() async {
        do {
            // Count total rooms
            var roomCount = 0
            for hotel in hotels {
                let rooms: [Room] = try await supabase
                    .from("rooms_with_images")
                    .select()
                    .eq("hotel_id", value: hotel.id.uuidString)
                    .execute()
                    .value
                roomCount += rooms.count
            }
            totalRooms = roomCount
            
        } catch {
            print("❌ Error fetching stats:", error)
        }
    }
    
    // MARK: - Fetch Rooms for Hotel
    
    func fetchRooms(for hotelId: UUID) async {
        isLoading = true
        
        do {
            let fetchedRooms: [Room] = try await supabase
                .from("rooms_with_images")
                .select()
                .eq("hotel_id", value: hotelId.uuidString)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            rooms = fetchedRooms
            print("✅ Habitaciones del hotel: \(rooms.count)")
            
        } catch {
            errorMessage = "Error al cargar habitaciones: \(error.localizedDescription)"
            print("❌ Error fetching rooms:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Create Hotel
    
    func createHotel(name: String, location: String?, description: String?, imageUrl: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            struct NewHotel: Encodable {
                let name: String
                let location: String?
                let description: String?
                let image_url: String?
                let owner_id: String
                let amenities: [String]
            }
            
            let newHotel = NewHotel(
                name: name,
                location: location,
                description: description,
                image_url: imageUrl,
                owner_id: userId.uuidString,
                amenities: []
            )
            
            try await supabase
                .from("hotels")
                .insert(newHotel)
                .execute()
            
            print("✅ Hotel creado: \(name)")
            await fetchHotels()
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al crear hotel: \(error.localizedDescription)"
            print("❌ Error creating hotel:", error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Update Hotel
    
    func updateHotel(
        hotelId: UUID,
        name: String,
        location: String?,
        description: String?,
        imageUrl: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            struct UpdateHotel: Encodable {
                let name: String
                let location: String?
                let description: String?
                let image_url: String?
            }
            
            let updated = UpdateHotel(
                name: name,
                location: location,
                description: description,
                image_url: imageUrl
            )
            
            try await supabase
                .from("hotels")
                .update(updated)
                .eq("hotel_id", value: hotelId.uuidString)
                .execute()
            
            print("✅ Hotel actualizado: \(name)")
            await fetchHotels()
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al actualizar hotel: \(error.localizedDescription)"
            print("❌ Error updating hotel:", error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Create Room
    
    func createRoom(
        hotelId: UUID,
        roomNumber: String,
        roomType: RoomType,
        price: Decimal,
        capacity: Int,
        description: String?,
        amenities: [String]
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            struct NewRoom: Encodable {
                let hotel_id: String
                let room_number: String
                let room_type: String
                let price: Decimal
                let capacity: Int
                let description: String?
                let amenities: [String]
                let is_active: Bool
            }
            
            let newRoom = NewRoom(
                hotel_id: hotelId.uuidString,
                room_number: roomNumber,
                room_type: roomType.rawValue,
                price: price,
                capacity: capacity,
                description: description,
                amenities: amenities,
                is_active: true
            )
            
            try await supabase
                .from("rooms")
                .insert(newRoom)
                .execute()
            
            print("✅ Habitación creada: \(roomNumber)")
            await fetchRooms(for: hotelId)
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al crear habitación: \(error.localizedDescription)"
            print("❌ Error creating room:", error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Update Room
    
    func updateRoom(
        roomId: UUID,
        hotelId: UUID,
        roomNumber: String,
        roomType: RoomType,
        price: Decimal,
        capacity: Int,
        description: String?,
        amenities: [String]
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            struct UpdateRoom: Encodable {
                let room_number: String
                let room_type: String
                let price: Decimal
                let capacity: Int
                let description: String?
                let amenities: [String]
            }
            
            let updatedRoom = UpdateRoom(
                room_number: roomNumber,
                room_type: roomType.rawValue,
                price: price,
                capacity: capacity,
                description: description,
                amenities: amenities
            )
            
            try await supabase
                .from("rooms")
                .update(updatedRoom)
                .eq("room_id", value: roomId.uuidString)
                .execute()
            
            print("✅ Habitación actualizada: \(roomNumber)")
            await fetchRooms(for: hotelId)
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al actualizar habitación: \(error.localizedDescription)"
            print("❌ Error updating room:", error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Delete Hotel
    
    func deleteHotel(_ hotel: Hotel) async -> Bool {
        do {
            try await supabase
                .from("hotels")
                .delete()
                .eq("hotel_id", value: hotel.id.uuidString)
                .execute()
            
            print("✅ Hotel eliminado: \(hotel.name)")
            await fetchHotels()
            return true
            
        } catch {
            errorMessage = "Error al eliminar hotel: \(error.localizedDescription)"
            print("❌ Error deleting hotel:", error)
            return false
        }
    }
    
    // MARK: - Check Active Reservations for Room
    
    func hasActiveReservations(roomId: UUID) async -> Bool {
        do {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: today)
            
            let reservations: [AdminReservation] = try await supabase
                .from("admin_reservations_view")
                .select()
                .eq("room_id", value: roomId.uuidString)
                .in("status", values: ["confirmed", "checked_in"])
                .gte("end_date", value: todayStr)
                .execute()
                .value
            
            return !reservations.isEmpty
        } catch {
            print("❌ Error checking active reservations:", error)
            // On error, be safe and assume there are active reservations
            return true
        }
    }
    
    // MARK: - Delete Room
    
    func deleteRoom(_ room: Room, hotelId: UUID) async -> Bool {
        do {
            try await supabase
                .from("rooms")
                .delete()
                .eq("room_id", value: room.id.uuidString)
                .execute()
            
            print("✅ Habitación eliminada: \(room.roomNumber)")
            await fetchRooms(for: hotelId)
            return true
            
        } catch {
            errorMessage = "Error al eliminar habitación: \(error.localizedDescription)"
            print("❌ Error deleting room:", error)
            return false
        }
    }
    
    // MARK: - Toggle Room Active
    
    func toggleRoomActive(_ room: Room, hotelId: UUID) async {
        do {
            try await supabase
                .from("rooms")
                .update(["is_active": !room.isActive])
                .eq("room_id", value: room.id.uuidString)
                .execute()
            
            await fetchRooms(for: hotelId)
            
        } catch {
            print("❌ Error toggling room:", error)
        }
    }
}
