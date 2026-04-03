//
//  AnalyticsViewModel.swift
//  InnSight
//
//  ViewModel para analíticas del dashboard de administrador
//

import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var occupancyData: [OccupancyDataPoint] = []
    @Published var revenueData: [RevenueDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Resultado de la regresión lineal. `nil` si no hay suficientes datos.
    @Published var predictionResult: LinearRegressionResult?
    /// Indica si el modelo de predicción está cargando de forma independiente.
    @Published var isPredictionLoading = false

    // MARK: - Private Properties
    private let analyticsService    = AnalyticsService()
    private let predictionService   = LinearRegressionService()
    
    // MARK: - Computed Properties
    var hasOccupancyData: Bool {
        occupancyData.contains { $0.rate > 0 }
    }
    
    var hasRevenueData: Bool {
        revenueData.contains { $0.amount > 0 }
    }
    
    var averageOccupancy: Double {
        guard !occupancyData.isEmpty else { return 0 }
        return occupancyData.reduce(0) { $0 + $1.rate } / Double(occupancyData.count)
    }
    
    var totalRevenue: Decimal {
        revenueData.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    var totalRevenueFormatted: String {
        totalRevenue.toCurrency()
    }
    
    // MARK: - Fetch Analytics
    
    /// Fetches analytics data for the given owner, period, and optional hotel filter
    func fetchAnalytics(for ownerId: UUID, period: AnalyticsPeriod, hotelId: UUID?) async {
        isLoading = true
        errorMessage = nil

        do {
            try Task.checkCancellation()

            async let occupancy = analyticsService.fetchOccupancyData(
                ownerId: ownerId, period: period, hotelId: hotelId
            )
            async let revenue = analyticsService.fetchRevenueData(
                ownerId: ownerId, period: period, hotelId: hotelId
            )

            let (occ, rev) = try await (occupancy, revenue)

            occupancyData = occ
            revenueData = rev

            print("✅ Analytics loaded: \(occ.count) occupancy points, \(rev.count) revenue points")

        } catch is CancellationError {
            print("⚠️ Analytics fetch was cancelled")
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            print("⚠️ Analytics fetch was cancelled (URL)")
        } catch {
            errorMessage = "Error al cargar analíticas: \(error.localizedDescription)"
            print("❌ Error fetching analytics:", error)
        }

        isLoading = false

        // Cargar predicción de forma independiente (no bloquea el resto de la UI)
        await fetchPrediction(for: ownerId, hotelId: hotelId, period: period)
    }

    /// Calcula la regresión lineal adaptada al período seleccionado.
    func fetchPrediction(for ownerId: UUID, hotelId: UUID?, period: AnalyticsPeriod) async {
        isPredictionLoading = true
        do {
            try Task.checkCancellation()
            predictionResult = try await predictionService.fetchPrediction(
                ownerId: ownerId, hotelId: hotelId, period: period
            )
            if let r = predictionResult {
                print("✅ Prediction loaded – R²=\(String(format: "%.2f", r.reservationR2))")
            } else {
                print("ℹ️ Prediction: not enough data")
            }
        } catch is CancellationError {
            print("⚠️ Prediction fetch was cancelled")
        } catch {
            // La predicción es opcional: no mostramos error al usuario
            predictionResult = nil
            print("⚠️ Prediction fetch failed (non-critical):", error)
        }
        isPredictionLoading = false
    }
    
    // MARK: - Reset
    
    func reset() {
        occupancyData   = []
        revenueData     = []
        predictionResult = nil
        errorMessage    = nil
    }
}
