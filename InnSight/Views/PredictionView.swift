//
//  PredictionView.swift
//  InnSight
//
//  Tarjeta de predicción IA — muestra la tendencia histórica y el pronóstico
//  adaptado al período seleccionado (semana / mes / año).
//
//  Modelo: regresión lineal ponderada + ajuste estacional por mes del año.
//

import SwiftUI
import Charts

struct PredictionView: View {

    let result: LinearRegressionResult

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(AppColors.divider)
            chartSection
            Divider().background(AppColors.divider)
            predictionCards
            Divider().background(AppColors.divider)
            modelInfoRow
            Divider().background(AppColors.divider)
            confidenceBar
        }
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Predicción IA")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text(headerSubtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(result.trendLabel)
                .font(AppFonts.labelSmall)
                .foregroundColor(trendColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(trendColor.opacity(0.12))
                .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var headerSubtitle: String {
        switch result.period {
        case .week:  return "Regresión estacional · proyección semanal"
        case .month: return "Regresión estacional · proyección mensual"
        case .year:  return "Regresión estacional · proyección anual"
        }
    }

    // MARK: - Chart (13 meses históricos + 2 meses proyectados)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reservaciones por mes · últimos 13 meses")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            Chart {
                // ── Línea histórica ──────────────────────────────────────────
                ForEach(result.historicalPoints) { point in
                    LineMark(
                        x: .value("Mes", point.index),
                        y: .value("Reservaciones", point.reservations),
                        series: .value("serie", "hist")
                    )
                    .foregroundStyle(AppColors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Mes", point.index),
                        y: .value("Reservaciones", point.reservations)
                    )
                    .foregroundStyle(AppColors.primary)
                    .symbolSize(20)
                }

                // ── Línea de predicción (punteada) ────────────────────────────
                ForEach(result.bridgeAndPredictionPoints) { point in
                    LineMark(
                        x: .value("Mes", point.index),
                        y: .value("Reservaciones", point.reservations),
                        series: .value("serie", "pred")
                    )
                    .foregroundStyle(AppColors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [6, 4]))

                    if point.isPrediction {
                        PointMark(
                            x: .value("Mes", point.index),
                            y: .value("Reservaciones", point.reservations)
                        )
                        .foregroundStyle(AppColors.accent)
                        .symbolSize(70)
                        .symbol(.diamond)
                        .annotation(position: .top, spacing: 4) {
                            Text("\(point.reservations)")
                                .font(AppFonts.labelSmall)
                                .foregroundColor(AppColors.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // ── Separador "Hoy" ─────────────────────────────────────────
                RuleMark(x: .value("Hoy", 12.5))
                    .foregroundStyle(AppColors.divider)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .center, spacing: 2) {
                        Text("Hoy")
                            .font(AppFonts.overline)
                            .foregroundColor(AppColors.textTertiary)
                    }
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    if let idx = value.as(Int.self) {
                        AxisValueLabel {
                            Text(labelForIndex(idx))
                                .font(AppFonts.overline)
                                .foregroundColor(idx >= 13 ? AppColors.accent : AppColors.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(AppFonts.overline)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .frame(height: 180)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Prediction Cards

    @ViewBuilder
    private var predictionCards: some View {
        VStack(spacing: 10) {
            HStack {
                Text(predictionSectionTitle)
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }

            if result.period == .year {
                annualCard(period: result.nextPeriod)
            } else {
                HStack(spacing: 12) {
                    periodCard(
                        period      : result.nextPeriod,
                        seasonIndex : result.nextPeriodSeasonIndex,
                        isNext      : true
                    )
                    if let after = result.periodAfter {
                        periodCard(
                            period      : after,
                            seasonIndex : result.periodAfterSeasonIndex ?? 1.0,
                            isNext      : false
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var predictionSectionTitle: String {
        switch result.period {
        case .week:  return "Pronóstico semanal"
        case .month: return "Pronóstico mensual"
        case .year:  return "Proyección anual"
        }
    }

    // Tarjeta para semana/mes — incluye badge estacional
    private func periodCard(
        period      : PredictionPeriod,
        seasonIndex : Double,
        isNext      : Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: ícono + etiqueta + badge estacional + "Próximo"
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.accent)
                Text(period.label)
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.accent)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                // Badge estacional
                Text(seasonalBadge(for: seasonIndex))
                    .font(AppFonts.overline)
                    .foregroundColor(seasonalBadgeColor(for: seasonIndex))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(seasonalBadgeColor(for: seasonIndex).opacity(0.12))
                    .cornerRadius(4)
                if isNext {
                    Text("Próximo")
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.surfaceSecondary)
                        .cornerRadius(4)
                }
            }

            Text(period.subtitle)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(period.reservations)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("reserv.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.success)
                Text(period.revenueFormatted)
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.success)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.accent.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(period.label): \(period.reservations) reservaciones, \(period.revenueFormatted)")
    }

    // Tarjeta anual (ocupa todo el ancho)
    private func annualCard(period: PredictionPeriod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.accent)
                    Text(period.label)
                        .font(AppFonts.titleMedium)
                        .foregroundColor(AppColors.accent)
                        .fontWeight(.bold)
                }
                Spacer()
                Text(period.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            Divider().background(AppColors.divider)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reservaciones")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(period.reservations)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("reserv.")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Text("~\(Int((Double(period.reservations) / 12).rounded())) / mes")
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                }

                Divider()
                    .frame(height: 60)
                    .background(AppColors.divider)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingresos estimados")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(period.revenueFormatted)
                        .font(AppFonts.headlineSmall)
                        .foregroundColor(AppColors.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("promedio mensual: \((period.revenueDecimal / 12).toCurrency())")
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Nota de ajuste estacional
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textTertiary)
                Text("Proyección con ajuste estacional por mes")
                    .font(AppFonts.overline)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(16)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.accent.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Proyección \(period.label): \(period.reservations) reservaciones, \(period.revenueFormatted)")
    }

    // MARK: - Model Info Row

    private var modelInfoRow: some View {
        HStack(spacing: 16) {
            Label {
                Text("\(result.dataMonthsUsed) meses de datos")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            } icon: {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }

            Divider().frame(height: 14)

            Label {
                Text(result.trendRateLabel)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            } icon: {
                Image(systemName: result.monthlySlope >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 11))
                    .foregroundColor(result.monthlySlope >= 0 ? AppColors.success : AppColors.error)
            }

            Divider().frame(height: 14)

            Label {
                Text("Est. aplicada")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            } icon: {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Confidence Bar

    private var confidenceBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)

                Text("Confianza del modelo")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surfaceSecondary)
                            .frame(height: 6)
                        Capsule()
                            .fill(confidenceGradient)
                            .frame(width: geo.size.width * CGFloat(min(result.reservationR2, 1.0)),
                                   height: 6)
                            .animation(.easeInOut(duration: 0.8), value: result.reservationR2)
                    }
                }
                .frame(height: 6)

                Text("R²=\(String(format: "%.2f", result.reservationR2))")
                    .font(AppFonts.labelSmall)
                    .foregroundColor(confidenceColor)
                    .fontWeight(.semibold)

                Text(result.confidenceLabel)
                    .font(AppFonts.labelSmall)
                    .foregroundColor(confidenceColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(confidenceColor.opacity(0.12))
                    .cornerRadius(20)
            }

            Text(result.confidenceExplanation)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Confianza del modelo: \(result.confidenceLabel), R² \(String(format: "%.2f", result.reservationR2)). \(result.confidenceExplanation)"
        )
    }

    // MARK: - Helpers

    private var trendColor: Color {
        let label = result.trendLabel
        if label.contains("↑") { return AppColors.success }
        if label.contains("↓") { return AppColors.error }
        return AppColors.textSecondary
    }

    private var confidenceColor: Color {
        switch result.reservationR2 {
        case 0.65...: return AppColors.success
        case 0.35..<0.65: return AppColors.warning
        default: return AppColors.error
        }
    }

    private var confidenceGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.warning, confidenceColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // xAxisValues: índices 0-12 son históricos (cada 2), 13-14 son predicciones
    private var xAxisValues: [Int] { [0, 2, 4, 6, 8, 10, 12, 13, 14] }

    private func labelForIndex(_ index: Int) -> String {
        if let p = result.historicalPoints.first(where: { $0.index == index }) { return p.label }
        if let p = result.bridgeAndPredictionPoints.first(where: { $0.index == index }) { return p.label }
        return ""
    }

    private func seasonalBadge(for index: Double) -> String {
        if index >= 1.15 { return "↑ T. alta" }
        if index <= 0.85 { return "↓ T. baja" }
        return "→ Normal"
    }

    private func seasonalBadgeColor(for index: Double) -> Color {
        if index >= 1.15 { return AppColors.success }
        if index <= 0.85 { return AppColors.warning }
        return AppColors.textSecondary
    }
}

// MARK: - Insufficient Data Placeholder

struct PredictionInsufficientDataView: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 28))
                .foregroundColor(AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Predicción IA")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text("Se necesitan al menos 3 meses de reservaciones para generar predicciones.")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now      = Date()

    // 13 puntos históricos (índices 0-12)
    let hist = (0..<13).map { i -> MonthlyPoint in
        let d    = calendar.date(byAdding: .month, value: i - 12, to: now)!
        let fmt  = DateFormatter()
        fmt.locale     = Locale(identifier: "es_MX")
        fmt.dateFormat = "MMM"
        let counts = [7, 9, 8, 11, 9, 10, 11, 10, 12, 12, 13, 14, 14]
        return MonthlyPoint(index: i, date: d, label: fmt.string(from: d).capitalized,
                            reservations: counts[i], revenue: Double(counts[i]) * 18000,
                            isPrediction: false)
    }

    let bridge = hist.last!
    let pred1  = MonthlyPoint(index: 13, date: now, label: "May", reservations: 16,
                              revenue: 288000, isPrediction: true)
    let pred2  = MonthlyPoint(index: 14, date: now, label: "Jun", reservations: 14,
                              revenue: 252000, isPrediction: true)

    let sampleSeasonalIndices: [Int: Double] = [
        1: 1.05, 2: 1.02, 3: 1.08, 4: 1.11, 5: 1.12, 6: 0.98,
        7: 1.36, 8: 1.02, 9: 0.69, 10: 0.67, 11: 0.74, 12: 1.17
    ]

    let result = LinearRegressionResult(
        period                    : .month,
        historicalPoints          : hist,
        bridgeAndPredictionPoints : [bridge, pred1, pred2],
        nextPeriod : PredictionPeriod(
            label: "May", subtitle: "Mayo 2026", reservations: 16, revenueDecimal: 288000
        ),
        periodAfter: PredictionPeriod(
            label: "Jun", subtitle: "Junio 2026", reservations: 14, revenueDecimal: 252000
        ),
        reservationR2         : 0.988,
        revenueR2             : 0.971,
        monthlySlope          : 0.52,
        dataMonthsUsed        : 13,
        seasonalIndices       : sampleSeasonalIndices,
        nextPeriodSeasonIndex : 1.12,   // Mayo → T. normal (casi alta)
        periodAfterSeasonIndex: 0.98    // Junio → Normal
    )

    ScrollView {
        VStack(spacing: 20) {
            PredictionView(result: result)

            // Preview modo año
            let yearResult = LinearRegressionResult(
                period                    : .year,
                historicalPoints          : hist,
                bridgeAndPredictionPoints : [bridge, pred1, pred2],
                nextPeriod : PredictionPeriod(
                    label: "2027", subtitle: "proyección de año completo",
                    reservations: 195, revenueDecimal: 3510000
                ),
                periodAfter           : nil,
                reservationR2         : 0.988,
                revenueR2             : 0.971,
                monthlySlope          : 0.52,
                dataMonthsUsed        : 13,
                seasonalIndices       : sampleSeasonalIndices,
                nextPeriodSeasonIndex : 1.0,
                periodAfterSeasonIndex: nil
            )
            PredictionView(result: yearResult)
        }
        .padding()
    }
    .background(AppColors.background)
}
