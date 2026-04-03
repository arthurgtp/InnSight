//
//  PredictionView.swift
//  InnSight
//
//  Tarjeta de predicción IA — muestra la tendencia histórica y el pronóstico
//  adaptado al período seleccionado (semana / mes / año).
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
        case .week:  return "Regresión lineal · proyección semanal"
        case .month: return "Regresión lineal · proyección mensual"
        case .year:  return "Regresión lineal · proyección anual"
        }
    }

    // MARK: - Chart (siempre 12 meses históricos + 2 meses proyectados)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reservaciones por mes · últimos 12 meses")
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
                RuleMark(x: .value("Hoy", 11.5))
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
                                .foregroundColor(idx >= 12 ? AppColors.accent : AppColors.textSecondary)
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
                // Modo Año → tarjeta única anual
                annualCard(period: result.nextPeriod)
            } else {
                // Modo Semana / Mes → dos tarjetas
                HStack(spacing: 12) {
                    periodCard(period: result.nextPeriod, isNext: true)
                    if let after = result.periodAfter {
                        periodCard(period: after, isNext: false)
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

    // Tarjeta para semana/mes
    private func periodCard(period: PredictionPeriod, isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

    private var xAxisValues: [Int] { [0, 2, 4, 6, 8, 10, 11, 12, 13] }

    private func labelForIndex(_ index: Int) -> String {
        if let p = result.historicalPoints.first(where: { $0.index == index }) { return p.label }
        if let p = result.bridgeAndPredictionPoints.first(where: { $0.index == index }) { return p.label }
        return ""
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

    let hist = (0..<12).map { i -> MonthlyPoint in
        let d    = calendar.date(byAdding: .month, value: i - 11, to: now)!
        let fmt  = DateFormatter()
        fmt.locale     = Locale(identifier: "es_MX")
        fmt.dateFormat = "MMM"
        let counts = [7, 9, 8, 11, 9, 10, 11, 10, 12, 12, 13, 14]
        return MonthlyPoint(index: i, date: d, label: fmt.string(from: d).capitalized,
                            reservations: counts[i], revenue: Double(counts[i]) * 18000,
                            isPrediction: false)
    }

    let bridge = hist.last!
    let pred1  = MonthlyPoint(index: 12, date: now, label: "Abr", reservations: 15,
                              revenue: 270000, isPrediction: true)
    let pred2  = MonthlyPoint(index: 13, date: now, label: "May", reservations: 16,
                              revenue: 288000, isPrediction: true)

    let result = LinearRegressionResult(
        period                    : .month,
        historicalPoints          : hist,
        bridgeAndPredictionPoints : [bridge, pred1, pred2],
        nextPeriod : PredictionPeriod(
            label: "Abr", subtitle: "Abril 2026", reservations: 15, revenueDecimal: 270000
        ),
        periodAfter: PredictionPeriod(
            label: "May", subtitle: "Mayo 2026", reservations: 16, revenueDecimal: 288000
        ),
        reservationR2 : 0.82,
        revenueR2     : 0.79,
        monthlySlope  : 0.61,
        dataMonthsUsed: 12
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
                    reservations: 185, revenueDecimal: 3330000
                ),
                periodAfter   : nil,
                reservationR2 : 0.82,
                revenueR2     : 0.79,
                monthlySlope  : 0.61,
                dataMonthsUsed: 12
            )
            PredictionView(result: yearResult)
        }
        .padding()
    }
    .background(AppColors.background)
}
