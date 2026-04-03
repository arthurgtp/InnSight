//
//  LinearRegressionService.swift
//  InnSight
//
//  Calcula regresión lineal sobre reservaciones e ingresos mensuales
//  y genera predicciones adaptadas al período seleccionado (semana / mes / año).
//

import Foundation
import Supabase

// MARK: - Monthly Data Point

struct MonthlyPoint: Identifiable {
    let id           = UUID()
    let index        : Int      // 0 = mes más antiguo, 11 = mes actual
    let date         : Date
    let label        : String   // "Jun", "Jul", etc.
    let reservations : Int
    let revenue      : Double
    let isPrediction : Bool
}

// MARK: - Prediction Period
//  Representa un período proyectado (semana, mes o año según contexto)

struct PredictionPeriod {
    /// Etiqueta corta: "Abr", "31 mar–6 abr", "2027"
    let label        : String
    /// Descripción larga: "Abril 2026", "próxima semana", "2027 completo"
    let subtitle     : String
    let reservations : Int
    let revenueDecimal: Decimal

    var revenueFormatted: String { revenueDecimal.toCurrency() }
    var reservationsText: String {
        reservations == 1 ? "1 reservación" : "\(reservations) reservaciones"
    }
}

// MARK: - Linear Regression Result

struct LinearRegressionResult {
    /// Período para el que se calculó la predicción
    let period        : AnalyticsPeriod
    /// 12 puntos históricos mensuales (siempre mensuales, para la gráfica)
    let historicalPoints          : [MonthlyPoint]
    /// Último punto histórico + 2 predicciones mensuales (conecta la línea)
    let bridgeAndPredictionPoints : [MonthlyPoint]

    /// Predicción del próximo período (semana / mes / año)
    let nextPeriod  : PredictionPeriod
    /// Predicción del período siguiente — nil para el modo Año
    let periodAfter : PredictionPeriod?

    /// R² del modelo de reservaciones (0–1)
    let reservationR2 : Double
    /// R² del modelo de ingresos (0–1)
    let revenueR2     : Double
    /// Cambio de reservaciones por mes según la regresión (pendiente)
    let monthlySlope  : Double
    /// Meses que tenían al menos 1 reservación (calidad del dato)
    let dataMonthsUsed: Int

    // MARK: - Computed helpers

    /// Etiqueta de confianza — umbrales calibrados para datos de hotelería
    var confidenceLabel: String {
        switch reservationR2 {
        case 0.65...: return "Alta"
        case 0.35..<0.65: return "Media"
        default: return "Baja"
        }
    }

    /// Explicación breve del nivel de confianza
    var confidenceExplanation: String {
        switch reservationR2 {
        case 0.65...:
            return "El modelo captura bien la tendencia histórica."
        case 0.35..<0.65:
            return "Existe variación estacional que el modelo lineal no captura por completo."
        default:
            return "Alta variabilidad en los datos. Úsalo como referencia general."
        }
    }

    /// Etiqueta de tendencia general
    var trendLabel: String {
        if monthlySlope > 0.25  { return "al alza ↑" }
        if monthlySlope < -0.25 { return "a la baja ↓" }
        return "estable →"
    }

    /// Tasa de cambio expresada en las unidades del período
    var trendRateLabel: String {
        switch period {
        case .week:
            let weeklySlope = monthlySlope / 4.348
            let sign = weeklySlope >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", weeklySlope)) reserv./semana"
        case .month:
            let sign = monthlySlope >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", monthlySlope)) reserv./mes"
        case .year:
            let yearlySlope = Int((monthlySlope * 12).rounded())
            let sign = yearlySlope >= 0 ? "+" : ""
            return "\(sign)\(yearlySlope) reserv./año"
        }
    }
}

// MARK: - Linear Regression Service

final class LinearRegressionService {

    // MARK: - Public API

    /// Obtiene los últimos 12 meses de datos, aplica regresión lineal y genera
    /// predicciones adaptadas al `period` seleccionado.
    /// Retorna `nil` si no hay suficientes datos (< 3 meses con reservaciones).
    func fetchPrediction(
        ownerId : UUID,
        hotelId : UUID?,
        period  : AnalyticsPeriod
    ) async throws -> LinearRegressionResult? {

        let calendar = Calendar.current
        let now      = Date()

        // Inicio del rango: primer día del mes, hace 11 meses
        let startDate = calendar.date(
            byAdding : .month, value: -11,
            to       : calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        )!

        let dateFmt = ISO8601DateFormatter()
        dateFmt.formatOptions = [.withFullDate]

        // 1. Hoteles del owner
        let hotels: [Hotel] = try await supabase
            .from("hotels")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .execute()
            .value

        let targetIds: [UUID] = hotelId.map { [$0] } ?? hotels.map { $0.id }
        guard !targetIds.isEmpty else { return nil }

        // 2. Reservaciones activas de los últimos 12 meses
        let reservations: [AdminReservation] = try await supabase
            .from("admin_reservations_view")
            .select()
            .in("hotel_id", values: targetIds.map { $0.uuidString })
            .gte("start_date", value: dateFmt.string(from: startDate))
            .execute()
            .value

        let active = reservations.filter {
            $0.status != .cancelled && $0.status != .noShow
        }

        // 3. Agrupar por mes (primer día del mes en hora local)
        var monthly: [Date: (count: Int, revenue: Double)] = [:]
        for res in active {
            let key  = calendar.date(from: calendar.dateComponents([.year, .month], from: res.startDate))!
            let prev = monthly[key] ?? (0, 0.0)
            monthly[key] = (
                prev.count + 1,
                prev.revenue + NSDecimalNumber(decimal: res.totalPrice).doubleValue
            )
        }

        // 4. Construir 12 buckets (incluye meses con 0 reservaciones)
        let monthFmt = DateFormatter()
        monthFmt.locale     = Locale(identifier: "es_MX")
        monthFmt.dateFormat = "MMM"

        var buckets: [(date: Date, label: String, count: Int, revenue: Double)] = []
        for i in 0..<12 {
            let d    = calendar.date(byAdding: .month, value: i, to: startDate)!
            let data = monthly[d] ?? (0, 0.0)
            buckets.append((d, monthFmt.string(from: d).capitalized, data.count, data.revenue))
        }

        let dataMonths = buckets.filter { $0.count > 0 }.count
        guard dataMonths >= 3 else { return nil }

        // 5. Regresión lineal sobre reservaciones e ingresos (x = 0…11)
        let xs   = (0..<12).map { Double($0) }
        let yRes = buckets.map { Double($0.count) }
        let yRev = buckets.map { $0.revenue }

        let resReg = linearRegression(x: xs, y: yRes)
        let revReg = linearRegression(x: xs, y: yRev)

        // Predictor auxiliar (resultado nunca negativo)
        let predictRes: (Double) -> Double = { x in max(0, resReg.slope * x + resReg.intercept) }
        let predictRev: (Double) -> Double = { x in max(0, revReg.slope * x + revReg.intercept) }

        // 6. Dos predicciones mensuales (siempre se calculan para la gráfica)
        let predRes12 = predictRes(12)
        let predRes13 = predictRes(13)
        let predRev12 = predictRev(12)
        let predRev13 = predictRev(13)

        let nextMonthDate  = calendar.date(byAdding: .month, value: 12, to: startDate)!
        let afterMonthDate = calendar.date(byAdding: .month, value: 13, to: startDate)!
        let nextMonthLabel  = monthFmt.string(from: nextMonthDate).capitalized
        let afterMonthLabel = monthFmt.string(from: afterMonthDate).capitalized

        // 7. Puntos históricos y de predicción para la gráfica (siempre mensuales)
        let historicalPoints = buckets.enumerated().map { i, b in
            MonthlyPoint(index: i, date: b.date, label: b.label,
                         reservations: b.count, revenue: b.revenue, isPrediction: false)
        }

        let bridge = MonthlyPoint(
            index: 11, date: buckets[11].date, label: buckets[11].label,
            reservations: buckets[11].count, revenue: buckets[11].revenue,
            isPrediction: false
        )
        let predPoint1 = MonthlyPoint(
            index: 12, date: nextMonthDate, label: nextMonthLabel,
            reservations: Int(predRes12.rounded()), revenue: predRev12,
            isPrediction: true
        )
        let predPoint2 = MonthlyPoint(
            index: 13, date: afterMonthDate, label: afterMonthLabel,
            reservations: Int(predRes13.rounded()), revenue: predRev13,
            isPrediction: true
        )

        // 8. Predicciones adaptadas al período seleccionado
        let monthYearFmt = DateFormatter()
        monthYearFmt.locale     = Locale(identifier: "es_MX")
        monthYearFmt.dateFormat = "MMMM yyyy"

        let shortFmt = DateFormatter()
        shortFmt.locale     = Locale(identifier: "es_MX")
        shortFmt.dateFormat = "d MMM"

        let weeksPerMonth = 365.25 / 12.0 / 7.0    // ≈ 4.348

        let nextPeriod  : PredictionPeriod
        let periodAfter : PredictionPeriod?

        switch period {

        // ── Semana ──────────────────────────────────────────────────────────
        case .week:
            // Escalar la predicción mensual a semanas
            let weekStart1 = calendar.date(byAdding: .day, value: 1,
                                           to: calendar.startOfDay(for: now))!
            let weekEnd1   = calendar.date(byAdding: .day, value: 7, to: weekStart1)!
            let weekStart2 = weekEnd1
            let weekEnd2   = calendar.date(byAdding: .day, value: 7, to: weekStart2)!

            let wRes1 = max(1, Int((predRes12 / weeksPerMonth).rounded()))
            let wRes2 = max(1, Int((predRes13 / weeksPerMonth).rounded()))
            let wRev1 = predRev12 / weeksPerMonth
            let wRev2 = predRev13 / weeksPerMonth

            nextPeriod = PredictionPeriod(
                label    : "\(shortFmt.string(from: weekStart1))–\(shortFmt.string(from: weekEnd1))",
                subtitle : "próxima semana",
                reservations  : wRes1,
                revenueDecimal: Decimal(wRev1)
            )
            periodAfter = PredictionPeriod(
                label    : "\(shortFmt.string(from: weekStart2))–\(shortFmt.string(from: weekEnd2))",
                subtitle : "semana siguiente",
                reservations  : wRes2,
                revenueDecimal: Decimal(wRev2)
            )

        // ── Mes ─────────────────────────────────────────────────────────────
        case .month:
            nextPeriod = PredictionPeriod(
                label    : nextMonthLabel,
                subtitle : monthYearFmt.string(from: nextMonthDate).capitalized,
                reservations  : Int(predRes12.rounded()),
                revenueDecimal: Decimal(predRev12)
            )
            periodAfter = PredictionPeriod(
                label    : afterMonthLabel,
                subtitle : monthYearFmt.string(from: afterMonthDate).capitalized,
                reservations  : Int(predRes13.rounded()),
                revenueDecimal: Decimal(predRev13)
            )

        // ── Año ─────────────────────────────────────────────────────────────
        case .year:
            // Suma de los 12 meses proyectados (x = 12…23)
            let yearRes = (12..<24).reduce(0.0) { $0 + predictRes(Double($1)) }
            let yearRev = (12..<24).reduce(0.0) { $0 + predictRev(Double($1)) }
            let nextYear = calendar.component(.year, from: nextMonthDate)

            nextPeriod = PredictionPeriod(
                label    : "\(nextYear)",
                subtitle : "proyección de año completo",
                reservations  : Int(yearRes.rounded()),
                revenueDecimal: Decimal(yearRev)
            )
            periodAfter = nil
        }

        return LinearRegressionResult(
            period                    : period,
            historicalPoints          : historicalPoints,
            bridgeAndPredictionPoints : [bridge, predPoint1, predPoint2],
            nextPeriod  : nextPeriod,
            periodAfter : periodAfter,
            reservationR2 : resReg.r2,
            revenueR2     : revReg.r2,
            monthlySlope  : resReg.slope,
            dataMonthsUsed: dataMonths
        )
    }

    // MARK: - Linear Regression Math (pure Swift, no external libraries)

    /// Calcula los coeficientes y R² de una regresión lineal simple: ŷ = slope·x + intercept
    private func linearRegression(
        x: [Double], y: [Double]
    ) -> (slope: Double, intercept: Double, r2: Double) {

        let n = Double(x.count)
        guard n > 1 else { return (0, y.first ?? 0, 0) }

        let sumX  = x.reduce(0, +)
        let sumY  = y.reduce(0, +)
        let sumXY = zip(x, y).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = x.reduce(0.0) { $0 + $1 * $1 }

        let denom = n * sumX2 - sumX * sumX
        guard abs(denom) > 1e-10 else { return (0, sumY / n, 0) }

        let slope     = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n

        // R² = 1 - SS_res / SS_tot
        let yMean = sumY / n
        let ssTot = y.reduce(0.0) { $0 + ($1 - yMean) * ($1 - yMean) }
        let ssRes = zip(x, y).reduce(0.0) { acc, pair in
            let ŷ = slope * pair.0 + intercept
            return acc + (pair.1 - ŷ) * (pair.1 - ŷ)
        }
        let r2 = ssTot > 1e-10 ? max(0, 1.0 - ssRes / ssTot) : 0

        return (slope, intercept, r2)
    }
}
