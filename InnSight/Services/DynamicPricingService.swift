//
//  DynamicPricingService.swift
//  InnSight
//
//  Calcula ajustes de precio sugeridos combinando:
//    1. Eventos del calendario mexicano (días festivos, vacaciones, puentes, fines de semana)
//    2. Índices estacionales del modelo WLS-Seasonal (resultado de la regresión)
//
//  El multiplicador final = evento.demandMultiplier × factor_estacional
//  Rango permitido: [0.70, 1.60] del precio base de la habitación.
//

import Foundation
import Supabase

final class DynamicPricingService {

    static let shared = DynamicPricingService()

    private let calendar = MexicanCalendarService.shared

    // MARK: - Public API

    /// Genera los `PricingBundle` para los próximos `daysAhead` días.
    /// - Parameters:
    ///   - hotels:     Lista de hoteles del admin. Se genera un bundle por hotel × evento.
    ///   - roomsByHotel: Diccionario [hotelId → [Room]]. Solo hoteles con cuartos generan bundles.
    ///   - regression:  Resultado opcional del modelo ML (para ajustar por estacionalidad mensual).
    ///   - daysAhead:   Ventana de tiempo en días (por defecto 75).
    func calculateBundles(
        hotels       : [Hotel],
        roomsByHotel : [UUID: [Room]],
        regression   : LinearRegressionResult?,
        daysAhead    : Int = 75
    ) -> [PricingBundle] {

        let events = calendar.upcomingEvents(days: daysAhead)

        // Quitar fines de semana ya cubiertos por vacaciones/festivos
        let significantEvents = deduplicateEvents(events)

        var bundles: [PricingBundle] = []

        for hotel in hotels {
            guard let rooms = roomsByHotel[hotel.id], !rooms.isEmpty else { continue }

            for event in significantEvents {
                // Factor estacional del ML para el mes del evento (si disponible)
                let seasonFactor = seasonalFactor(for: event.startDate, regression: regression)

                // Multiplicador final, acotado a [0.70, 1.60]
                let finalMultiplier = min(1.60, max(0.70, event.demandMultiplier * seasonFactor))

                // Ajuste por habitación
                let adjustments = rooms.map { room -> PriceAdjustment in
                    let suggested = roundToNearest50(
                        NSDecimalNumber(decimal: room.price).doubleValue * finalMultiplier
                    )
                    return PriceAdjustment(
                        id            : UUID(),
                        roomId        : room.id,
                        roomNumber    : room.roomNumber,
                        roomType      : room.roomType,
                        basePrice     : room.price,
                        suggestedPrice: Decimal(suggested),
                        multiplier    : finalMultiplier
                    )
                }

                bundles.append(PricingBundle(
                    id          : UUID(),
                    event       : modifiedEvent(event, multiplier: finalMultiplier),
                    hotelId     : hotel.id,
                    hotelName   : hotel.name,
                    adjustments : adjustments
                ))
            }
        }

        // Ordenar: primero los que están más próximos
        return bundles.sorted { $0.event.startDate < $1.event.startDate }
    }

    // MARK: - Apply adjustment in Supabase

    /// Actualiza el precio de un array de habitaciones en Supabase.
    /// Retorna los UUIDs de los cuartos actualizados exitosamente.
    func applyAdjustments(
        _ adjustments: [PriceAdjustment]
    ) async throws {
        for adj in adjustments {
            struct PriceUpdate: Encodable { let price: Decimal }
            try await supabase
                .from("rooms")
                .update(PriceUpdate(price: adj.suggestedPrice))
                .eq("room_id", value: adj.roomId.uuidString)
                .execute()
        }
    }

    // MARK: - Private helpers

    /// Calcula un factor multiplicador a partir del índice estacional ML.
    /// El índice > 1.0 (T. Alta) aumenta el multiplicador; < 1.0 (T. Baja) lo reduce.
    /// El efecto es moderado: ±10% máximo para no sobredimensionar el ajuste.
    private func seasonalFactor(
        for date: Date,
        regression: LinearRegressionResult?
    ) -> Double {
        guard let reg = regression else { return 1.0 }
        let month = Calendar.current.component(.month, from: date)
        let idx   = reg.seasonalIndices[month] ?? 1.0
        // Escala: índice 1.0 → factor 1.0 ; índice 1.25 → factor 1.05 ; índice 0.75 → factor 0.95
        let factor = 1.0 + (idx - 1.0) * 0.20
        return min(1.15, max(0.85, factor))
    }

    /// Elimina eventos de menor prioridad que solapen con otros de mayor prioridad.
    /// Prioridad: holiday > vacation > bridge > weekend.
    private func deduplicateEvents(_ events: [CalendarEvent]) -> [CalendarEvent] {
        let priority: [CalendarEventType: Int] = [
            .holiday: 4, .vacation: 3, .bridge: 2, .weekend: 1, .lowWeekday: 0,
            .highSeason: 0, .lowSeason: 0
        ]
        var result: [CalendarEvent] = []

        for event in events {
            let overlaps = result.contains { existing in
                existing.startDate <= event.endDate && existing.endDate >= event.startDate
            }
            if overlaps {
                // Solo reemplazar si el nuevo tiene mayor prioridad
                let existingPriority = result.filter { ex in
                    ex.startDate <= event.endDate && ex.endDate >= event.startDate
                }.compactMap { priority[$0.type] }.max() ?? 0
                let newPriority = priority[event.type] ?? 0
                if newPriority > existingPriority {
                    result.removeAll { ex in
                        ex.startDate <= event.endDate && ex.endDate >= event.startDate
                    }
                    result.append(event)
                }
                // Si misma prioridad, mantener ambos si no son del mismo tipo
                else if newPriority == existingPriority {
                    result.append(event)
                }
            } else {
                result.append(event)
            }
        }
        return result.sorted { $0.startDate < $1.startDate }
    }

    /// Crea un CalendarEvent con el multiplicador final ya calculado (para display).
    private func modifiedEvent(_ event: CalendarEvent, multiplier: Double) -> CalendarEvent {
        CalendarEvent(
            name        : event.name,
            startDate   : event.startDate,
            endDate     : event.endDate,
            type        : event.type,
            extraMultiplier: multiplier / event.type.baseMultiplier,
            description : event.description
        )
    }

    /// Redondea al múltiplo de 50 más cercano (precios más "limpios").
    private func roundToNearest50(_ value: Double) -> Double {
        (value / 50.0).rounded() * 50.0
    }
}
