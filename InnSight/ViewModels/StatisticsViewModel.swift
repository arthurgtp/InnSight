//
//  StatisticsViewModel.swift
//  InnSight
//
//  ViewModel para estadísticas del dashboard de administrador
//

import Foundation
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalHotels = 0
    @Published var totalRooms = 0
    @Published var totalReservations = 0
    @Published var totalRevenue: Decimal = 0
    
    @Published var hotelsTrend: TrendIndicator?
    @Published var roomsTrend: TrendIndicator?
    @Published var reservationsTrend: TrendIndicator?
    @Published var revenueTrend: TrendIndicator?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let statisticsService = StatisticsService()
    
    // MARK: - Computed Properties
    var totalRevenueFormatted: String {
        totalRevenue.toCurrency()
    }
    
    var hasData: Bool {
        totalHotels > 0 || totalRooms > 0 || totalReservations > 0
    }
    
    // MARK: - Fetch Statistics
    
    /// Fetches dashboard statistics for the given owner
    func fetchStatistics(for ownerId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for cancellation before starting
            try Task.checkCancellation()
            
            // Fetch current period stats
            let currentStats = try await statisticsService.fetchDashboardStats(for: ownerId)
            
            // Check for cancellation after first fetch
            try Task.checkCancellation()
            
            // Update published properties
            totalHotels = currentStats.totalHotels
            totalRooms = currentStats.totalRooms
            totalReservations = currentStats.totalReservations
            totalRevenue = currentStats.totalRevenue
            
            // Fetch previous period stats for trend calculation
            let previousStats = try await statisticsService.fetchPreviousPeriodStats(for: ownerId)
            
            // Calculate trends
            let trends = calculateTrends(current: currentStats, previous: previousStats)
            hotelsTrend = trends.hotelsTrend
            roomsTrend = trends.roomsTrend
            reservationsTrend = trends.reservationsTrend
            revenueTrend = trends.revenueTrend
            
            print("✅ Statistics loaded: \(totalHotels) hotels, \(totalRooms) rooms, \(totalReservations) reservations")
            
        } catch is CancellationError {
            // Task was cancelled, don't show error to user
            print("⚠️ Statistics fetch was cancelled")
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // URL request was cancelled, don't show error to user
            print("⚠️ Statistics fetch was cancelled (URL)")
        } catch {
            errorMessage = "Error al cargar estadísticas: \(error.localizedDescription)"
            print("❌ Error fetching statistics:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Calculate Trends
    
    /// Calculates trend indicators comparing current and previous period statistics
    func calculateTrends(current: DashboardStats, previous: DashboardStats) -> TrendData {
        TrendData.calculate(current: current, previous: previous)
    }
    
    // MARK: - Reset
    
    /// Resets all statistics to initial state
    func reset() {
        totalHotels = 0
        totalRooms = 0
        totalReservations = 0
        totalRevenue = 0
        hotelsTrend = nil
        roomsTrend = nil
        reservationsTrend = nil
        revenueTrend = nil
        errorMessage = nil
    }
}
