//
//  DynamicPricingModels.swift
//  InnSight
//
//  Modelos para precios dinámicos basados en calendario mexicano + predicciones ML.
//

import Foundation
import SwiftUI

// Alias local para no duplicar la extensión Color(hex:) que ya existe en AppColors.swift
private func hexColor(_ hex: String) -> Color { Color(hex: hex) }

// MARK: - Calendar Event Type

enum CalendarEventType: String, CaseIterable {
    case holiday        = "Día festivo"
    case vacation       = "Vacaciones"
    case bridge         = "Puente"
    case weekend        = "Fin de semana"
    case lowWeekday     = "Bין semana baja"
    case highSeason     = "Temporada alta ML"
    case lowSeason      = "Temporada baja ML"

    var icon: String {
        switch self {
        case .holiday:      return "star.fill"
        case .vacation:     return "sun.max.fill"
        case .bridge:       return "road.lanes"
        case .weekend:      return "moon.stars.fill"
        case .lowWeekday:   return "minus.circle"
        case .highSeason:   return "chart.line.uptrend.xyaxis"
        case .lowSeason:    return "chart.line.downtrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .holiday:      return hexColor("ef4444")   // rojo
        case .vacation:     return hexColor("f59e0b")   // naranja
        case .bridge:       return hexColor("8b5cf6")   // morado
        case .weekend:      return hexColor("3b82f6")   // azul
        case .lowWeekday:   return hexColor("6b7280")   // gris
        case .highSeason:   return hexColor("10b981")   // verde
        case .lowSeason:    return hexColor("6b7280")   // gris
        }
    }

    /// Multiplicador base sobre el precio de la habitación
    var baseMultiplier: Double {
        switch self {
        case .holiday:      return 1.30
        case .vacation:     return 1.25
        case .bridge:       return 1.20
        case .weekend:      return 1.10
        case .lowWeekday:   return 0.90
        case .highSeason:   return 1.15
        case .lowSeason:    return 0.85
        }
    }
}

// MARK: - Calendar Event

struct CalendarEvent: Identifiable {
    let id           : UUID
    let name         : String
    let startDate    : Date
    let endDate      : Date
    let type         : CalendarEventType
    /// Multiplicador de demanda calculado (incluye ajuste estacional ML si aplica)
    let demandMultiplier: Double
    let description  : String

    init(name: String, startDate: Date, endDate: Date,
         type: CalendarEventType, extraMultiplier: Double = 1.0,
         description: String = "") {
        self.id               = UUID()
        self.name             = name
        self.startDate        = startDate
        self.endDate          = endDate
        self.type             = type
        self.demandMultiplier = type.baseMultiplier * extraMultiplier
        self.description      = description
    }

    var dateRangeLabel: String {
        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "es_MX")
        fmt.dateFormat = "d MMM"
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return fmt.string(from: startDate)
        }
        return "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate))"
    }

    var daysUntil: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: startDate).day ?? 0
        return max(0, days)
    }

    var percentChange: Int {
        Int(((demandMultiplier - 1.0) * 100).rounded())
    }

    var isIncrease: Bool { demandMultiplier >= 1.0 }
}

// MARK: - Price Adjustment (per room)

struct PriceAdjustment: Identifiable {
    let id           : UUID
    let roomId       : UUID
    let roomNumber   : String
    let roomType     : RoomType
    let basePrice    : Decimal
    let suggestedPrice: Decimal
    let multiplier   : Double

    var percentChange: Int {
        Int(((multiplier - 1.0) * 100).rounded())
    }

    var basePriceFormatted: String      { basePrice.toCurrency() }
    var suggestedPriceFormatted: String { suggestedPrice.toCurrency() }
}

// MARK: - Dynamic Price Info (para vista del cliente al reservar)

struct DynamicPriceInfo {
    /// Precio base sin ajuste (el que tiene la habitación en BD)
    let baseNightlyPrice  : Decimal
    /// Precio ajustado por noche (puede ser igual si no hay evento)
    let adjustedNightlyPrice: Decimal
    /// Total por todas las noches con el precio ajustado
    let totalPrice        : Decimal
    /// Multiplicador efectivo promedio del período (1.0 = sin cambio)
    let multiplier        : Double
    /// Evento principal que justifica el ajuste (nil = precio normal)
    let event             : CalendarEvent?
    /// Número de noches de la estancia
    let nights            : Int

    var isAdjusted      : Bool   { abs(multiplier - 1.0) > 0.01 }
    var percentChange   : Int    { Int(((multiplier - 1.0) * 100).rounded()) }
    var isIncrease      : Bool   { multiplier > 1.0 }

    var basePriceFormatted    : String { baseNightlyPrice.toCurrency() }
    var adjustedPriceFormatted: String { adjustedNightlyPrice.toCurrency() }
    var totalPriceFormatted   : String { totalPrice.toCurrency() }

    var adjustmentLabel: String {
        guard isAdjusted else { return "" }
        let sign = isIncrease ? "+" : ""
        return "\(sign)\(percentChange)%"
    }
}

// MARK: - Pricing Bundle (event + all room adjustments)

struct PricingBundle: Identifiable {
    let id          : UUID
    let event       : CalendarEvent
    let hotelId     : UUID
    let hotelName   : String
    /// Ajuste sugerido por habitación
    let adjustments : [PriceAdjustment]
    var isApplied   : Bool    = false
    var appliedAt   : Date?   = nil

    var averageMultiplier: Double {
        guard !adjustments.isEmpty else { return 1.0 }
        return adjustments.reduce(0) { $0 + $1.multiplier } / Double(adjustments.count)
    }

    var averagePercentChange: Int {
        Int(((averageMultiplier - 1.0) * 100).rounded())
    }
}
