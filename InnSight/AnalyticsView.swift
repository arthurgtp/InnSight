//
//  AnalyticsView.swift
//  InnSight
//
//  Vista principal de analíticas con gráficos de ocupación e ingresos
//

import SwiftUI
import Supabase

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedHotel: Hotel?
    
    let hotels: [Hotel]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filters
                filtersSection
                
                // Content
                if viewModel.isLoading {
                    loadingState
                } else if let error = viewModel.errorMessage {
                    errorState(message: error)
                } else if hotels.isEmpty {
                    analyticsEmptyState
                } else {
                    chartsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppColors.background)
        .task {
            await loadAnalytics()
        }
        .onChange(of: selectedPeriod) {
            Task { await loadAnalytics() }
        }
        .onChange(of: selectedHotel) {
            Task { await loadAnalytics() }
        }
        .refreshable {
            await loadAnalytics()
        }
    }
    
    // MARK: - Load Analytics
    
    private func loadAnalytics() async {
        do {
            let session = try await supabase.auth.session
            await viewModel.fetchAnalytics(
                for: session.user.id,
                period: selectedPeriod,
                hotelId: selectedHotel?.id
            )
        } catch {
            print("❌ Error getting session for analytics: \(error)")
        }
    }
    
    // MARK: - Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Period Selector
            HStack(spacing: 0) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(AppFonts.labelMedium)
                            .foregroundColor(selectedPeriod == period ? .white : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedPeriod == period ? AppColors.primary : Color.clear)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Periodo: \(period.rawValue)")
                    .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                }
            }
            .padding(4)
            .background(AppColors.surfaceSecondary)
            .cornerRadius(12)

            // Hotel Filter
            if hotels.count > 1 {
                Menu {
                    Button {
                        selectedHotel = nil
                    } label: {
                        HStack {
                            Text("Todos los hoteles")
                            if selectedHotel == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(hotels) { hotel in
                        Button {
                            selectedHotel = hotel
                        } label: {
                            HStack {
                                Text(hotel.name)
                                if selectedHotel?.id == hotel.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                        
                        Text(selectedHotel?.name ?? "Todos los hoteles")
                            .font(AppFonts.labelMedium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Filtrar por hotel: \(selectedHotel?.name ?? "Todos")")
            }
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(spacing: 16) {
            // Summary cards
            HStack(spacing: 12) {
                summaryCard(
                    title: "Ocupación Prom.",
                    value: String(format: "%.1f%%", viewModel.averageOccupancy),
                    icon: "bed.double.fill",
                    color: AppColors.primary
                )
                
                summaryCard(
                    title: "Ingresos Total",
                    value: viewModel.totalRevenueFormatted,
                    icon: "dollarsign.circle.fill",
                    color: AppColors.accent
                )
            }
            
            // Occupancy Chart
            OccupancyChartView(data: viewModel.occupancyData, period: selectedPeriod)
            
            // Revenue Chart
            RevenueChartView(data: viewModel.revenueData, period: selectedPeriod)
        }
    }
    
    // MARK: - Summary Card
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.surface)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    // MARK: - Analytics Empty State
    
    private var analyticsEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin datos de analíticas")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Agrega hoteles y recibe reservaciones para ver tus analíticas")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sin datos de analíticas. Agrega hoteles y recibe reservaciones para ver tus analíticas.")
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Cargando analíticas...")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
                Task { await loadAnalytics() }
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
            .accessibilityLabel("Reintentar carga de analíticas")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView(hotels: [])
}
