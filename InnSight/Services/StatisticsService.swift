//
//  StatisticsService.swift
//  InnSight
//
//  Servicio para obtener estadísticas del dashboard de administrador
//

import Foundation
import Supabase

class StatisticsService {
    
    // MARK: - Fetch Dashboard Stats
    
    /// Fetches current period dashboard statistics for an admin user
    func fetchDashboardStats(for ownerId: UUID) async throws -> DashboardStats {
        // Get current period dates (current month)
        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart)!
        
        // Fetch hotels count
        let hotels: [Hotel] = try await supabase
            .from("hotels")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .execute()
            .value
        
        let totalHotels = hotels.count
        
        // Fetch rooms count across all hotels
        var totalRooms = 0
        var hotelIds: [UUID] = []
        
        for hotel in hotels {
            hotelIds.append(hotel.id)
            let rooms: [Room] = try await supabase
                .from("rooms_with_images")
                .select()
                .eq("hotel_id", value: hotel.id.uuidString)
                .execute()
                .value
            totalRooms += rooms.count
        }
        
        // Fetch reservations and calculate revenue — filtered to current month (by start_date)
        var totalReservations = 0
        var totalRevenue: Decimal = 0

        if !hotelIds.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]

            let reservations: [AdminReservation] = try await supabase
                .from("admin_reservations_view")
                .select()
                .in("hotel_id", values: hotelIds.map { $0.uuidString })
                .gte("start_date", value: dateFormatter.string(from: periodStart))
                .lte("start_date", value: dateFormatter.string(from: periodEnd))
                .execute()
                .value

            let activeReservations = reservations.filter {
                $0.status != .cancelled && $0.status != .noShow
            }
            totalReservations = activeReservations.count
            totalRevenue = activeReservations.reduce(Decimal(0)) { $0 + $1.totalPrice }
        }
        
        return DashboardStats(
            totalHotels: totalHotels,
            totalRooms: totalRooms,
            totalReservations: totalReservations,
            totalRevenue: totalRevenue,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
    }
    
    // MARK: - Fetch Previous Period Stats
    
    /// Fetches previous period statistics for trend comparison
    func fetchPreviousPeriodStats(for ownerId: UUID) async throws -> DashboardStats {
        // Get previous period dates (previous month)
        let calendar = Calendar.current
        let now = Date()
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart)!
        let periodEnd = calendar.date(byAdding: .day, value: -1, to: currentMonthStart)!
        
        // Fetch hotels count (same as current - hotels don't change by period)
        let hotels: [Hotel] = try await supabase
            .from("hotels")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .execute()
            .value
        
        let totalHotels = hotels.count
        
        // Fetch rooms count (same as current - rooms don't change by period)
        var totalRooms = 0
        var hotelIds: [UUID] = []
        
        for hotel in hotels {
            hotelIds.append(hotel.id)
            let rooms: [Room] = try await supabase
                .from("rooms_with_images")
                .select()
                .eq("hotel_id", value: hotel.id.uuidString)
                .execute()
                .value
            totalRooms += rooms.count
        }
        
        // Fetch reservations from previous period
        var totalReservations = 0
        var totalRevenue: Decimal = 0
        
        if !hotelIds.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            
            let reservations: [AdminReservation] = try await supabase
                .from("admin_reservations_view")
                .select()
                .in("hotel_id", values: hotelIds.map { $0.uuidString })
                .gte("start_date", value: dateFormatter.string(from: periodStart))
                .lte("start_date", value: dateFormatter.string(from: periodEnd))
                .execute()
                .value

            let activeReservations = reservations.filter {
                $0.status != .cancelled && $0.status != .noShow
            }
            totalReservations = activeReservations.count
            totalRevenue = activeReservations.reduce(Decimal(0)) { $0 + $1.totalPrice }
        }
        
        return DashboardStats(
            totalHotels: totalHotels,
            totalRooms: totalRooms,
            totalReservations: totalReservations,
            totalRevenue: totalRevenue,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
    }
}
