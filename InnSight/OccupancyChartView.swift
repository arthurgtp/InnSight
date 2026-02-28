//
//  OccupancyChartView.swift
//  InnSight
//
//  Gráfico de tasas de ocupación usando Swift Charts
//

import SwiftUI
import Charts

struct OccupancyChartView: View {
    let data: [OccupancyDataPoint]
    let period: AnalyticsPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(AppColors.primary)
                
                Text("Tasa de Ocupación")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !data.isEmpty {
                    let avg = data.reduce(0) { $0 + $1.rate } / Double(data.count)
                    Text("Prom: \(String(format: "%.1f", avg))%")
                        .font(AppFonts.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if data.isEmpty || !data.contains(where: { $0.rate > 0 }) {
                emptyState
            } else {
                chartContent
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Chart
    
    private var chartContent: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Periodo", point.label),
                y: .value("Ocupación", point.rate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text("\(Int(val))%")
                            .font(AppFonts.overline)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(AppColors.divider)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(AppFonts.overline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Gráfico de ocupación")
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin datos de ocupación")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Los datos aparecerán cuando tengas reservaciones")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        OccupancyChartView(
            data: [
                OccupancyDataPoint(date: Date(), rate: 65, label: "Lun"),
                OccupancyDataPoint(date: Date(), rate: 72, label: "Mar"),
                OccupancyDataPoint(date: Date(), rate: 80, label: "Mié"),
                OccupancyDataPoint(date: Date(), rate: 55, label: "Jue"),
                OccupancyDataPoint(date: Date(), rate: 90, label: "Vie"),
                OccupancyDataPoint(date: Date(), rate: 95, label: "Sáb"),
                OccupancyDataPoint(date: Date(), rate: 88, label: "Dom")
            ],
            period: .week
        )
        
        OccupancyChartView(data: [], period: .week)
    }
    .padding()
    .background(AppColors.background)
}
