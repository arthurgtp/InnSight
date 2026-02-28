//
//  AnalyticsService.swift
//  InnSight
//
//  Servicio para obtener datos de analíticas (ocupación e ingresos)
//

import Foundation
import Supabase

// MARK: - Analytics Period

enum AnalyticsPeriod: String, CaseIterable {
    case week = "Semana"
    case month = "Mes"
    case year = "Año"
}

// MARK: - Data Points

struct OccupancyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
    let label: String
}

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
    let label: String
}

// MARK: - Analytics Service

class AnalyticsService {
    
    // MARK: - Fetch Occupancy Data
    
    /// Fetches occupancy rate data for the given period and optional hotel filter
    func fetchOccupancyData(ownerId: UUID, period: AnalyticsPeriod, hotelId: UUID?) async throws -> [OccupancyDataPoint] {
        let (startDate, _) = dateRange(for: period)
        
        // Fetch owner's hotels
        let hotels: [Hotel] = try await supabase
            .from("hotels")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .execute()
            .value
        
        var targetHotelIds: [UUID]
        if let hotelId = hotelId {
            targetHotelIds = [hotelId]
        } else {
            targetHotelIds = hotels.map { $0.id }
        }
        
        guard !targetHotelIds.isEmpty else { return [] }
        
        // Fetch rooms for target hotels
        var totalRooms = 0
        for hid in targetHotelIds {
            let rooms: [Room] = try await supabase
                .from("rooms_with_images")
                .select()
                .eq("hotel_id", value: hid.uuidString)
                .eq("is_active", value: true)
                .execute()
                .value
            totalRooms += rooms.count
        }
        
        guard totalRooms > 0 else { return [] }

        // Fetch reservations in the period
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let reservations: [AdminReservation] = try await supabase
            .from("admin_reservations_view")
            .select()
            .in("hotel_id", values: targetHotelIds.map { $0.uuidString })
            .gte("end_date", value: dateFormatter.string(from: startDate))
            .execute()
            .value
        
        // Filter out cancelled reservations
        let activeReservations = reservations.filter { $0.status != .cancelled }
        
        // Calculate occupancy per bucket
        let buckets = dateBuckets(for: period)
        
        return buckets.map { bucket in
            let occupiedNights = calculateOccupiedRoomNights(
                reservations: activeReservations,
                bucketStart: bucket.start,
                bucketEnd: bucket.end
            )
            let totalNights = totalRooms * max(1, Calendar.current.dateComponents([.day], from: bucket.start, to: bucket.end).day ?? 1)
            let rate = totalNights > 0 ? min(Double(occupiedNights) / Double(totalNights) * 100, 100) : 0
            
            return OccupancyDataPoint(date: bucket.start, rate: rate, label: bucket.label)
        }
    }
    
    // MARK: - Fetch Revenue Data
    
    /// Fetches revenue trend data for the given period and optional hotel filter
    func fetchRevenueData(ownerId: UUID, period: AnalyticsPeriod, hotelId: UUID?) async throws -> [RevenueDataPoint] {
        let (startDate, _) = dateRange(for: period)
        
        // Fetch owner's hotels
        let hotels: [Hotel] = try await supabase
            .from("hotels")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .execute()
            .value
        
        var targetHotelIds: [UUID]
        if let hotelId = hotelId {
            targetHotelIds = [hotelId]
        } else {
            targetHotelIds = hotels.map { $0.id }
        }
        
        guard !targetHotelIds.isEmpty else { return [] }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let reservations: [AdminReservation] = try await supabase
            .from("admin_reservations_view")
            .select()
            .in("hotel_id", values: targetHotelIds.map { $0.uuidString })
            .gte("created_at", value: dateFormatter.string(from: startDate))
            .execute()
            .value
        
        // Filter out cancelled reservations
        let activeReservations = reservations.filter { $0.status != .cancelled }
        
        // Aggregate revenue per bucket
        let buckets = dateBuckets(for: period)
        
        return buckets.map { bucket in
            let bucketRevenue = activeReservations
                .filter { $0.createdAt >= bucket.start && $0.createdAt < bucket.end }
                .reduce(Decimal(0)) { $0 + $1.totalPrice }
            
            return RevenueDataPoint(date: bucket.start, amount: bucketRevenue, label: bucket.label)
        }
    }

    // MARK: - Private Helpers
    
    private struct DateBucket {
        let start: Date
        let end: Date
        let label: String
    }
    
    /// Returns the overall date range for the analytics period
    private func dateRange(for period: AnalyticsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))!
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .month, value: -11, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (start, now)
        }
    }
    
    /// Generates date buckets for grouping data points
    private func dateBuckets(for period: AnalyticsPeriod) -> [DateBucket] {
        let calendar = Calendar.current
        let now = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_MX")
        
        switch period {
        case .week:
            // 7 daily buckets
            dayFormatter.dateFormat = "EEE"
            return (0..<7).map { offset in
                let day = calendar.date(byAdding: .day, value: -(6 - offset), to: calendar.startOfDay(for: now))!
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
                return DateBucket(start: day, end: nextDay, label: dayFormatter.string(from: day).capitalized)
            }
            
        case .month:
            // 4 weekly buckets
            dayFormatter.dateFormat = "dd MMM"
            let startOfRange = calendar.date(byAdding: .day, value: -27, to: calendar.startOfDay(for: now))!
            return (0..<4).map { offset in
                let weekStart = calendar.date(byAdding: .day, value: offset * 7, to: startOfRange)!
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                return DateBucket(start: weekStart, end: weekEnd, label: dayFormatter.string(from: weekStart))
            }
            
        case .year:
            // 12 monthly buckets
            dayFormatter.dateFormat = "MMM"
            let startMonth = calendar.date(byAdding: .month, value: -11, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (0..<12).map { offset in
                let monthStart = calendar.date(byAdding: .month, value: offset, to: startMonth)!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                return DateBucket(start: monthStart, end: monthEnd, label: dayFormatter.string(from: monthStart).capitalized)
            }
        }
    }
    
    /// Calculates the number of occupied room-nights within a bucket
    private func calculateOccupiedRoomNights(reservations: [AdminReservation], bucketStart: Date, bucketEnd: Date) -> Int {
        var totalNights = 0
        
        for reservation in reservations {
            // Find overlap between reservation dates and bucket dates
            let overlapStart = max(reservation.startDate, bucketStart)
            let overlapEnd = min(reservation.endDate, bucketEnd)
            
            if overlapStart < overlapEnd {
                let nights = Calendar.current.dateComponents([.day], from: overlapStart, to: overlapEnd).day ?? 0
                totalNights += max(0, nights)
            }
        }
        
        return totalNights
    }
}
