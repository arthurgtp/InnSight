//
//  RevenueChartView.swift
//  InnSight
//
//  Gráfico de tendencia de ingresos usando Swift Charts
//

import SwiftUI
import Charts

struct RevenueChartView: View {
    let data: [RevenueDataPoint]
    let period: AnalyticsPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.accent)
                
                Text("Ingresos")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !data.isEmpty {
                    let total = data.reduce(Decimal(0)) { $0 + $1.amount }
                    Text("Total: \(total.toCurrency())")
                        .font(AppFonts.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if data.isEmpty || !data.contains(where: { $0.amount > 0 }) {
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
            LineMark(
                x: .value("Periodo", point.label),
                y: .value("Ingresos", NSDecimalNumber(decimal: point.amount).doubleValue)
            )
            .foregroundStyle(AppColors.accent)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Periodo", point.label),
                y: .value("Ingresos", NSDecimalNumber(decimal: point.amount).doubleValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.accent.opacity(0.3), AppColors.accent.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Periodo", point.label),
                y: .value("Ingresos", NSDecimalNumber(decimal: point.amount).doubleValue)
            )
            .foregroundStyle(AppColors.accent)
            .symbolSize(30)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(Decimal(val).toCurrencyShort())
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
        .accessibilityLabel("Gráfico de ingresos")
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin datos de ingresos")
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

// MARK: - Decimal Short Currency Extension

extension Decimal {
    /// Formats decimal as short currency (e.g., $1.5K, $2.3M)
    func toCurrencyShort() -> String {
        let number = NSDecimalNumber(decimal: self).doubleValue
        if number >= 1_000_000 {
            return String(format: "$%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "$%.1fK", number / 1_000)
        } else {
            return String(format: "$%.0f", number)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        RevenueChartView(
            data: [
                RevenueDataPoint(date: Date(), amount: 12500, label: "Lun"),
                RevenueDataPoint(date: Date(), amount: 8300, label: "Mar"),
                RevenueDataPoint(date: Date(), amount: 15000, label: "Mié"),
                RevenueDataPoint(date: Date(), amount: 9800, label: "Jue"),
                RevenueDataPoint(date: Date(), amount: 22000, label: "Vie"),
                RevenueDataPoint(date: Date(), amount: 28000, label: "Sáb"),
                RevenueDataPoint(date: Date(), amount: 18500, label: "Dom")
            ],
            period: .week
        )
        
        RevenueChartView(data: [], period: .week)
    }
    .padding()
    .background(AppColors.background)
}
