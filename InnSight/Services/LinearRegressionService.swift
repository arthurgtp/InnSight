//
//  LinearRegressionService.swift
//  InnSight
//
//  Calcula regresión lineal PONDERADA con ajuste ESTACIONAL sobre reservaciones
//  e ingresos mensuales, y genera predicciones adaptadas al período seleccionado.
//
//  Algoritmo:
//    1. Obtiene los últimos 13 meses de datos (un ciclo anual completo + 1 mes).
//    2. Aplica regresión ponderada (más peso a meses recientes).
//    3. Calcula índices estacionales por mes del año (ratio actual / tendencia).
//    4. Aplica el índice estacional del mes objetivo a cada predicción.
//    5. Calcula R² del modelo estacional completo (trend × seasonal vs actual).
//

import Foundation
import Supabase

// MARK: - Monthly Data Point

struct MonthlyPoint: Identifiable {
    let id           = UUID()
    let index        : Int      // 0 = mes más antiguo, 12 = mes actual
    let date         : Date
    let label        : String   // "Jun", "Jul", etc.
    let reservations : Int
    let revenue      : Double
    let isPrediction : Bool
}

// MARK: - Prediction Period

struct PredictionPeriod {
    let label         : String
    let subtitle      : String
    let reservations  : Int
    let revenueDecimal: Decimal

    var revenueFormatted: String { revenueDecimal.toCurrency() }
    var reservationsText: String {
        reservations == 1 ? "1 reservación" : "\(reservations) reservaciones"
    }
}

// MARK: - Linear Regression Result

struct LinearRegressionResult {
    let period                    : AnalyticsPeriod
    /// 13 puntos históricos mensuales (para la gráfica)
    let historicalPoints          : [MonthlyPoint]
    /// Último punto histórico + 2 predicciones mensuales (conecta la línea)
    let bridgeAndPredictionPoints : [MonthlyPoint]

    let nextPeriod  : PredictionPeriod
    let periodAfter : PredictionPeriod?

    /// R² del modelo estacional completo (trend × seasonal) para reservaciones
    let reservationR2 : Double
    /// R² del modelo estacional para ingresos
    let revenueR2     : Double
    /// Pendiente mensual (reservaciones/mes) de la regresión ponderada
    let monthlySlope  : Double
    /// Meses con al menos 1 reservación (calidad del dato)
    let dataMonthsUsed: Int

    /// Índices estacionales normalizados por mes del calendario (1=Ene … 12=Dic)
    let seasonalIndices         : [Int: Double]
    /// Índice estacional del mes al que corresponde nextPeriod
    let nextPeriodSeasonIndex   : Double
    /// Índice estacional del mes al que corresponde periodAfter (nil en modo Año)
    let periodAfterSeasonIndex  : Double?

    // MARK: - Computed helpers

    var confidenceLabel: String {
        switch reservationR2 {
        case 0.65...: return "Alta"
        case 0.35..<0.65: return "Media"
        default: return "Baja"
        }
    }

    var confidenceExplanation: String {
        switch reservationR2 {
        case 0.65...:
            return "El modelo estacional captura bien la tendencia y los patrones de temporada."
        case 0.35..<0.65:
            return "Precisión moderada: faltan meses para calibrar toda la estacionalidad."
        default:
            return "Alta variabilidad en los datos. Úsalo como referencia general."
        }
    }

    var trendLabel: String {
        if monthlySlope > 0.25  { return "al alza ↑" }
        if monthlySlope < -0.25 { return "a la baja ↓" }
        return "estable →"
    }

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

    /// Etiqueta de temporada para el próximo período
    var nextSeasonalBadge: String { seasonalBadge(for: nextPeriodSeasonIndex) }
    /// Etiqueta de temporada para el período siguiente (nil en modo Año)
    var periodAfterSeasonalBadge: String? { periodAfterSeasonIndex.map { seasonalBadge(for: $0) } }

    private func seasonalBadge(for index: Double) -> String {
        if index >= 1.15 { return "↑ T. alta" }
        if index <= 0.85 { return "↓ T. baja" }
        return "→ Normal"
    }
}

// MARK: - Linear Regression Service

final class LinearRegressionService {

    private let nBuckets = 13   // 12 meses históricos + mes actual = 1 ciclo completo

    // MARK: - Public API

    func fetchPrediction(
        ownerId : UUID,
        hotelId : UUID?,
        period  : AnalyticsPeriod
    ) async throws -> LinearRegressionResult? {

        let calendar = Calendar.current
        let now      = Date()

        // Primer día del mes actual, retrocediendo (nBuckets - 1) meses
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startDate = calendar.date(byAdding: .month, value: -(nBuckets - 1), to: currentMonthStart)!

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

        // 2. Reservaciones activas de los últimos 13 meses
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

        // 4. Construir nBuckets buckets (incluye meses con 0 reservaciones)
        let monthFmt = DateFormatter()
        monthFmt.locale     = Locale(identifier: "es_MX")
        monthFmt.dateFormat = "MMM"

        var buckets: [(date: Date, label: String, count: Int, revenue: Double)] = []
        for i in 0..<nBuckets {
            let d    = calendar.date(byAdding: .month, value: i, to: startDate)!
            let data = monthly[d] ?? (0, 0.0)
            buckets.append((d, monthFmt.string(from: d).capitalized, data.count, data.revenue))
        }

        let dataMonths = buckets.filter { $0.count > 0 }.count
        guard dataMonths >= 3 else { return nil }

        // 5. Regresión lineal PONDERADA (peso 0.5 → 1.0, antiguo → reciente)
        let xs      = (0..<nBuckets).map { Double($0) }
        let yRes    = buckets.map { Double($0.count) }
        let yRev    = buckets.map { $0.revenue }
        let weights = (0..<nBuckets).map { 0.5 + 0.5 * (Double($0) / Double(nBuckets - 1)) }

        let resReg = weightedLinearRegression(x: xs, y: yRes, weights: weights)
        let revReg = weightedLinearRegression(x: xs, y: yRev, weights: weights)

        let predictTrendRes: (Double) -> Double = { x in max(0, resReg.slope * x + resReg.intercept) }
        let predictTrendRev: (Double) -> Double = { x in max(0, revReg.slope * x + revReg.intercept) }

        // 6. Índices estacionales (por mes del calendario, normalizados a media = 1.0)
        let (seasonalRes, seasonalRev) = computeSeasonalIndices(
            buckets    : buckets,
            slopeRes   : resReg.slope, interceptRes: resReg.intercept,
            slopeRev   : revReg.slope, interceptRev: revReg.intercept,
            calendar   : calendar
        )

        // 7. R² del modelo estacional (trend × seasonal) vs actual
        let fittedRes = buckets.enumerated().map { i, b -> Double in
            let m = calendar.component(.month, from: b.date)
            return predictTrendRes(Double(i)) * (seasonalRes[m] ?? 1.0)
        }
        let fittedRev = buckets.enumerated().map { i, b -> Double in
            let m = calendar.component(.month, from: b.date)
            return predictTrendRev(Double(i)) * (seasonalRev[m] ?? 1.0)
        }
        let seasonalR2Res = computeR2(actual: yRes, fitted: fittedRes)
        let seasonalR2Rev = computeR2(actual: yRev, fitted: fittedRev)

        // 8. Fechas de los dos meses a predecir (índices nBuckets y nBuckets+1)
        let nextMonthDate  = calendar.date(byAdding: .month, value: nBuckets,     to: startDate)!
        let afterMonthDate = calendar.date(byAdding: .month, value: nBuckets + 1, to: startDate)!
        let nextMonthLabel  = monthFmt.string(from: nextMonthDate).capitalized
        let afterMonthLabel = monthFmt.string(from: afterMonthDate).capitalized

        let nextMonthNum  = calendar.component(.month, from: nextMonthDate)
        let afterMonthNum = calendar.component(.month, from: afterMonthDate)

        let si13Res = seasonalRes[nextMonthNum]  ?? 1.0
        let si14Res = seasonalRes[afterMonthNum] ?? 1.0
        let si13Rev = seasonalRev[nextMonthNum]  ?? 1.0
        let si14Rev = seasonalRev[afterMonthNum] ?? 1.0

        // Predicciones estacionalmente ajustadas
        let adjRes13 = predictTrendRes(Double(nBuckets))     * si13Res
        let adjRes14 = predictTrendRes(Double(nBuckets + 1)) * si14Res
        let adjRev13 = predictTrendRev(Double(nBuckets))     * si13Rev
        let adjRev14 = predictTrendRev(Double(nBuckets + 1)) * si14Rev

        // 9. Puntos para la gráfica
        let historicalPoints = buckets.enumerated().map { i, b in
            MonthlyPoint(index: i, date: b.date, label: b.label,
                         reservations: b.count, revenue: b.revenue, isPrediction: false)
        }

        let lastBucket = buckets[nBuckets - 1]
        let bridge = MonthlyPoint(
            index: nBuckets - 1, date: lastBucket.date, label: lastBucket.label,
            reservations: lastBucket.count, revenue: lastBucket.revenue, isPrediction: false
        )
        let predPoint1 = MonthlyPoint(
            index: nBuckets, date: nextMonthDate, label: nextMonthLabel,
            reservations: Int(adjRes13.rounded()), revenue: adjRev13, isPrediction: true
        )
        let predPoint2 = MonthlyPoint(
            index: nBuckets + 1, date: afterMonthDate, label: afterMonthLabel,
            reservations: Int(adjRes14.rounded()), revenue: adjRev14, isPrediction: true
        )

        // 10. Predicciones adaptadas al período seleccionado
        let monthYearFmt = DateFormatter()
        monthYearFmt.locale     = Locale(identifier: "es_MX")
        monthYearFmt.dateFormat = "MMMM yyyy"

        let shortFmt = DateFormatter()
        shortFmt.locale     = Locale(identifier: "es_MX")
        shortFmt.dateFormat = "d MMM"

        let weeksPerMonth = 365.25 / 12.0 / 7.0

        let nextPeriod          : PredictionPeriod
        let periodAfter         : PredictionPeriod?
        let nextPeriodSeasonIdx : Double
        let afterPeriodSeasonIdx: Double?

        switch period {

        // ── Semana ──────────────────────────────────────────────────────────
        case .week:
            let weekStart1 = calendar.date(byAdding: .day, value: 1,
                                           to: calendar.startOfDay(for: now))!
            let weekEnd1   = calendar.date(byAdding: .day, value: 7, to: weekStart1)!
            let weekStart2 = weekEnd1
            let weekEnd2   = calendar.date(byAdding: .day, value: 7, to: weekStart2)!

            let wRes1 = max(1, Int((adjRes13 / weeksPerMonth).rounded()))
            let wRes2 = max(1, Int((adjRes14 / weeksPerMonth).rounded()))

            nextPeriod = PredictionPeriod(
                label    : "\(shortFmt.string(from: weekStart1))–\(shortFmt.string(from: weekEnd1))",
                subtitle : "próxima semana",
                reservations  : wRes1,
                revenueDecimal: Decimal(adjRev13 / weeksPerMonth)
            )
            periodAfter = PredictionPeriod(
                label    : "\(shortFmt.string(from: weekStart2))–\(shortFmt.string(from: weekEnd2))",
                subtitle : "semana siguiente",
                reservations  : wRes2,
                revenueDecimal: Decimal(adjRev14 / weeksPerMonth)
            )
            nextPeriodSeasonIdx  = si13Res
            afterPeriodSeasonIdx = si14Res

        // ── Mes ─────────────────────────────────────────────────────────────
        case .month:
            nextPeriod = PredictionPeriod(
                label    : nextMonthLabel,
                subtitle : monthYearFmt.string(from: nextMonthDate).capitalized,
                reservations  : Int(adjRes13.rounded()),
                revenueDecimal: Decimal(adjRev13)
            )
            periodAfter = PredictionPeriod(
                label    : afterMonthLabel,
                subtitle : monthYearFmt.string(from: afterMonthDate).capitalized,
                reservations  : Int(adjRes14.rounded()),
                revenueDecimal: Decimal(adjRev14)
            )
            nextPeriodSeasonIdx  = si13Res
            afterPeriodSeasonIdx = si14Res

        // ── Año ─────────────────────────────────────────────────────────────
        case .year:
            // Suma de los 12 meses proyectados con ajuste estacional individual
            var yearRes = 0.0, yearRev = 0.0
            for offset in 0..<12 {
                let idx       = nBuckets + offset
                let monthDate = calendar.date(byAdding: .month, value: idx, to: startDate)!
                let mNum      = calendar.component(.month, from: monthDate)
                yearRes += max(0, predictTrendRes(Double(idx)) * (seasonalRes[mNum] ?? 1.0))
                yearRev += max(0, predictTrendRev(Double(idx)) * (seasonalRev[mNum] ?? 1.0))
            }
            let nextYear = calendar.component(.year, from: nextMonthDate)

            nextPeriod = PredictionPeriod(
                label    : "\(nextYear)",
                subtitle : "proyección de año completo",
                reservations  : Int(yearRes.rounded()),
                revenueDecimal: Decimal(yearRev)
            )
            periodAfter         = nil
            // Para año usamos el promedio de los índices disponibles
            let avgIdx = seasonalRes.values.reduce(0, +) / Double(max(1, seasonalRes.count))
            nextPeriodSeasonIdx  = avgIdx
            afterPeriodSeasonIdx = nil
        }

        return LinearRegressionResult(
            period                    : period,
            historicalPoints          : historicalPoints,
            bridgeAndPredictionPoints : [bridge, predPoint1, predPoint2],
            nextPeriod                : nextPeriod,
            periodAfter               : periodAfter,
            reservationR2             : seasonalR2Res,
            revenueR2                 : seasonalR2Rev,
            monthlySlope              : resReg.slope,
            dataMonthsUsed            : dataMonths,
            seasonalIndices           : seasonalRes,
            nextPeriodSeasonIndex     : nextPeriodSeasonIdx,
            periodAfterSeasonIndex    : afterPeriodSeasonIdx
        )
    }

    // MARK: - Weighted Linear Regression

    /// Regresión lineal simple ponderada: ŷ = slope·x + intercept
    private func weightedLinearRegression(
        x: [Double], y: [Double], weights: [Double]
    ) -> (slope: Double, intercept: Double, r2: Double) {

        let n = x.count
        guard n > 1 else { return (0, y.first ?? 0, 0) }

        var sw = 0.0, swx = 0.0, swy = 0.0, swxy = 0.0, swx2 = 0.0
        for i in 0..<n {
            sw   += weights[i]
            swx  += weights[i] * x[i]
            swy  += weights[i] * y[i]
            swxy += weights[i] * x[i] * y[i]
            swx2 += weights[i] * x[i] * x[i]
        }

        let denom = sw * swx2 - swx * swx
        guard abs(denom) > 1e-10 else { return (0, swy / sw, 0) }

        let slope     = (sw * swxy - swx * swy) / denom
        let intercept = (swy - slope * swx) / sw

        // R² no ponderado (más interpretable)
        let yMean = y.reduce(0, +) / Double(n)
        let ssTot = y.reduce(0.0) { $0 + ($1 - yMean) * ($1 - yMean) }
        var ssRes = 0.0
        for i in 0..<n {
            let yhat = slope * x[i] + intercept
            ssRes += (y[i] - yhat) * (y[i] - yhat)
        }
        let r2 = ssTot > 1e-10 ? max(0, 1.0 - ssRes / ssTot) : 0

        return (slope, intercept, r2)
    }

    // MARK: - Seasonal Indices

    /// Calcula índices estacionales normalizados por mes del calendario (1-12).
    /// Para cada bucket: ratio = actual / trend. Los ratios se promedian por mes
    /// y luego se normalizan para que su media sea 1.0. Meses sin datos → 1.0.
    private func computeSeasonalIndices(
        buckets     : [(date: Date, label: String, count: Int, revenue: Double)],
        slopeRes    : Double, interceptRes: Double,
        slopeRev    : Double, interceptRev: Double,
        calendar    : Calendar
    ) -> (reservations: [Int: Double], revenue: [Int: Double]) {

        var ratiosRes: [Int: [Double]] = [:]
        var ratiosRev: [Int: [Double]] = [:]

        for (i, bucket) in buckets.enumerated() {
            let trendRes = max(0.1, slopeRes * Double(i) + interceptRes)
            let trendRev = max(1.0, slopeRev * Double(i) + interceptRev)
            let m = calendar.component(.month, from: bucket.date)
            ratiosRes[m, default: []].append(Double(bucket.count) / trendRes)
            ratiosRev[m, default: []].append(bucket.revenue        / trendRev)
        }

        func normalize(_ ratios: [Int: [Double]]) -> [Int: Double] {
            // Promedio por mes
            var raw: [Int: Double] = [:]
            for (m, vals) in ratios {
                raw[m] = vals.reduce(0, +) / Double(vals.count)
            }
            // Meses sin datos → índice neutro
            for m in 1...12 where raw[m] == nil {
                raw[m] = 1.0
            }
            // Normalizar: media de los 12 índices = 1.0
            let avg = raw.values.reduce(0, +) / 12.0
            guard avg > 1e-10 else { return raw }
            return raw.mapValues { $0 / avg }
        }

        return (normalize(ratiosRes), normalize(ratiosRev))
    }

    // MARK: - R² Calculation

    private func computeR2(actual: [Double], fitted: [Double]) -> Double {
        guard actual.count == fitted.count, !actual.isEmpty else { return 0 }
        let mean  = actual.reduce(0, +) / Double(actual.count)
        let ssTot = actual.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
        var ssRes = 0.0
        for (a, f) in zip(actual, fitted) { ssRes += (a - f) * (a - f) }
        return ssTot > 1e-10 ? max(0, 1.0 - ssRes / ssTot) : 0
    }
}
