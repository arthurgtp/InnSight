//
//  StatisticsCardView.swift
//  InnSight
//
//  Componente reutilizable para mostrar estadísticas con indicador de tendencia
//

import SwiftUI

struct StatisticsCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendIndicator?
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Value
            Text(value)
                .font(AppFonts.headlineSmall)
                .foregroundColor(AppColors.textPrimary)
            
            // Title
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            // Trend indicator
            if let trend = trend {
                TrendIndicatorView(trend: trend)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppColors.surface)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(trend != nil ? "Tendencia: \(trend!.displayText)" : "")
    }
}

// MARK: - Trend Indicator View

struct TrendIndicatorView: View {
    let trend: TrendIndicator
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption2)
            
            Text(trend.displayText)
                .font(AppFonts.labelSmall)
        }
        .foregroundColor(trend.isPositive ? AppColors.success : AppColors.error)
        .accessibilityLabel("Tendencia \(trend.isPositive ? "positiva" : "negativa") de \(trend.displayText)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            StatisticsCardView(
                title: "Hoteles",
                value: "5",
                icon: "building.2.fill",
                color: AppColors.primary,
                trend: TrendIndicator(percentage: 25.0, isPositive: true)
            )
            
            StatisticsCardView(
                title: "Habitaciones",
                value: "42",
                icon: "bed.double.fill",
                color: AppColors.secondary,
                trend: TrendIndicator(percentage: -10.5, isPositive: false)
            )
        }
        
        HStack(spacing: 12) {
            StatisticsCardView(
                title: "Reservaciones",
                value: "128",
                icon: "calendar.badge.clock",
                color: AppColors.success,
                trend: nil
            )
            
            StatisticsCardView(
                title: "Ingresos",
                value: "$45,000",
                icon: "dollarsign.circle.fill",
                color: AppColors.accent,
                trend: TrendIndicator(percentage: 15.3, isPositive: true)
            )
        }
    }
    .padding()
    .background(AppColors.background)
}
