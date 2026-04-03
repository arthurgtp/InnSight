//
//  DashboardStats.swift
//  InnSight
//
//  Modelos para estadísticas del dashboard de administrador
//

import Foundation

// MARK: - Dashboard Statistics
struct DashboardStats: Codable {
    let totalHotels: Int
    let totalRooms: Int
    let totalReservations: Int
    let totalRevenue: Decimal
    let periodStart: Date
    let periodEnd: Date
    
    enum CodingKeys: String, CodingKey {
        case totalHotels = "total_hotels"
        case totalRooms = "total_rooms"
        case totalReservations = "total_reservations"
        case totalRevenue = "total_revenue"
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
    
    // MARK: - Computed Properties
    var totalRevenueFormatted: String {
        totalRevenue.toCurrency()
    }
    
    var periodDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_MX")
        return "\(formatter.string(from: periodStart)) - \(formatter.string(from: periodEnd))"
    }
    
    // Init for previews and tests
    init(totalHotels: Int, totalRooms: Int, totalReservations: Int, totalRevenue: Decimal, periodStart: Date, periodEnd: Date) {
        self.totalHotels = totalHotels
        self.totalRooms = totalRooms
        self.totalReservations = totalReservations
        self.totalRevenue = totalRevenue
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }
    
    // Empty stats for initial state
    static var empty: DashboardStats {
        DashboardStats(
            totalHotels: 0,
            totalRooms: 0,
            totalReservations: 0,
            totalRevenue: 0,
            periodStart: Date(),
            periodEnd: Date()
        )
    }
}

// MARK: - Trend Indicator
struct TrendIndicator {
    let percentage: Double
    let isPositive: Bool
    
    /// Calculates trend percentage between current and previous values
    /// Returns nil if previous value is zero (cannot calculate percentage change)
    static func calculate(current: Int, previous: Int) -> TrendIndicator? {
        guard previous != 0 else { return nil }
        let change = Double(current - previous) / Double(previous) * 100
        return TrendIndicator(percentage: change, isPositive: current >= previous)
    }
    
    /// Calculates trend percentage for Decimal values
    static func calculate(current: Decimal, previous: Decimal) -> TrendIndicator? {
        guard previous != 0 else { return nil }
        let currentDouble = NSDecimalNumber(decimal: current).doubleValue
        let previousDouble = NSDecimalNumber(decimal: previous).doubleValue
        let change = (currentDouble - previousDouble) / previousDouble * 100
        return TrendIndicator(percentage: change, isPositive: current >= previous)
    }
    
    // MARK: - Computed Properties
    var displayText: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentage))%"
    }
    
    var absolutePercentage: Double {
        abs(percentage)
    }
    
    var icon: String {
        isPositive ? "arrow.up.right" : "arrow.down.right"
    }
}

// MARK: - Trend Data (aggregated trends for dashboard)
struct TrendData {
    let hotelsTrend: TrendIndicator?
    let roomsTrend: TrendIndicator?
    let reservationsTrend: TrendIndicator?
    let revenueTrend: TrendIndicator?
    
    static func calculate(current: DashboardStats, previous: DashboardStats) -> TrendData {
        TrendData(
            hotelsTrend: TrendIndicator.calculate(current: current.totalHotels, previous: previous.totalHotels),
            roomsTrend: TrendIndicator.calculate(current: current.totalRooms, previous: previous.totalRooms),
            reservationsTrend: TrendIndicator.calculate(current: current.totalReservations, previous: previous.totalReservations),
            revenueTrend: TrendIndicator.calculate(current: current.totalRevenue, previous: previous.totalRevenue)
        )
    }
}
