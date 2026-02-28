//
//  OverviewSection.swift
//  InnSight
//
//  Sección de resumen con estadísticas del dashboard de administrador
//

import SwiftUI

struct OverviewSection: View {
    @ObservedObject var statisticsVM: StatisticsViewModel
    let onQuickAction: ((QuickActionType) -> Void)?
    let onRetry: (() -> Void)?
    
    init(statisticsVM: StatisticsViewModel, onQuickAction: ((QuickActionType) -> Void)? = nil, onRetry: (() -> Void)? = nil) {
        self.statisticsVM = statisticsVM
        self.onQuickAction = onQuickAction
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if statisticsVM.isLoading {
                loadingState
            } else if let errorMessage = statisticsVM.errorMessage {
                errorState(message: errorMessage)
            } else if !statisticsVM.hasData {
                emptyState
            } else {
                statisticsGrid
            }
        }
    }
    
    // MARK: - Statistics Grid
    
    private var statisticsGrid: some View {
        HStack(spacing: 12) {
            StatisticsCardView(
                title: "Reservaciones",
                value: "\(statisticsVM.totalReservations)",
                icon: "calendar.badge.clock",
                color: AppColors.success,
                trend: statisticsVM.reservationsTrend
            )
            
            StatisticsCardView(
                title: "Ingresos",
                value: statisticsVM.totalRevenueFormatted,
                icon: "dollarsign.circle.fill",
                color: AppColors.accent,
                trend: statisticsVM.revenueTrend
            )
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Cargando estadísticas...")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Error State
    
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(AppColors.error)
            
            Text(message)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                onRetry?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Reintentar")
                }
                .font(AppFonts.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.primary)
                .cornerRadius(8)
            }
            .accessibilityLabel("Reintentar carga de estadísticas")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin datos disponibles")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Agrega tu primer hotel para ver estadísticas")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let onQuickAction = onQuickAction {
                Button {
                    onQuickAction(.addHotel)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar Hotel")
                    }
                    .font(AppFonts.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Agregar primer hotel")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Type

enum QuickActionType {
    case addHotel
    case addRoom
    case viewReservations
    case viewAnalytics
}

// MARK: - Preview

#Preview("With Data") {
    OverviewSectionPreview.withData
}

#Preview("Empty State") {
    OverviewSectionPreview.emptyState
}

#Preview("Loading State") {
    OverviewSectionPreview.loadingState
}

#Preview("Error State") {
    OverviewSectionPreview.errorState
}

// MARK: - Preview Helpers

private enum OverviewSectionPreview {
    static var withData: some View {
        let vm = StatisticsViewModel()
        vm.totalHotels = 5
        vm.totalRooms = 42
        vm.totalReservations = 128
        vm.totalRevenue = 45000
        vm.hotelsTrend = TrendIndicator(percentage: 25.0, isPositive: true)
        vm.reservationsTrend = TrendIndicator(percentage: 15.3, isPositive: true)
        
        return OverviewSection(statisticsVM: vm)
            .padding()
            .background(AppColors.background)
    }
    
    static var emptyState: some View {
        let vm = StatisticsViewModel()
        
        return OverviewSection(statisticsVM: vm) { action in
            print("Quick action: \(action)")
        }
        .padding()
        .background(AppColors.background)
    }
    
    static var loadingState: some View {
        let vm = StatisticsViewModel()
        vm.isLoading = true
        
        return OverviewSection(statisticsVM: vm)
            .padding()
            .background(AppColors.background)
    }
    
    static var errorState: some View {
        let vm = StatisticsViewModel()
        vm.errorMessage = "Error de conexión. Por favor verifica tu conexión a internet."
        
        return OverviewSection(statisticsVM: vm)
            .padding()
            .background(AppColors.background)
    }
}
