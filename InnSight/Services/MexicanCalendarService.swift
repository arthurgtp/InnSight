//
//  MexicanCalendarService.swift
//  InnSight
//
//  Genera eventos del calendario mexicano para los próximos N días:
//  días festivos oficiales, vacaciones escolares SEP, puentes y fines de semana.
//

import Foundation

final class MexicanCalendarService {

    static let shared = MexicanCalendarService()
    private let cal = Calendar.current

    // MARK: - Public API

    /// Devuelve todos los eventos relevantes desde `from` hasta `from + days` días.
    /// Los eventos se ordenan cronológicamente y se filtran solapamientos,
    /// priorizando los de mayor impacto (holiday > vacation > bridge > weekend).
    func upcomingEvents(from startDate: Date = Date(), days: Int = 75) -> [CalendarEvent] {
        let endDate = cal.date(byAdding: .day, value: days, to: startDate)!

        var events: [CalendarEvent] = []

        for year in yearsInRange(from: startDate, to: endDate) {
            events += officialHolidays(year: year)
            events += schoolVacations(year: year)
            events += puentes(year: year)
        }
        events += weekends(from: startDate, to: endDate)

        // Filtrar los que caen en el rango
        let filtered = events.filter { ev in
            ev.endDate >= startDate && ev.startDate <= endDate
        }

        // Ordenar por fecha de inicio
        return filtered.sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Official Holidays (Ley Federal del Trabajo)

    private func officialHolidays(year: Int) -> [CalendarEvent] {
        var holidays: [CalendarEvent] = []

        // Año Nuevo
        holidays += makeHoliday("Año Nuevo", month: 1, day: 1, year: year,
                                description: "Inicio de año")

        // Día de la Constitución — primer lunes de febrero
        if let d = nthWeekday(.monday, n: 1, month: 2, year: year) {
            holidays.append(makeEvent("Día de la Constitución", start: d, end: d,
                                     type: .holiday, description: "Día festivo oficial"))
        }

        // Natalicio de Benito Juárez — tercer lunes de marzo
        if let d = nthWeekday(.monday, n: 3, month: 3, year: year) {
            holidays.append(makeEvent("Natalicio de Benito Juárez", start: d, end: d,
                                     type: .holiday, description: "Día festivo oficial"))
        }

        // Día del Trabajo
        holidays += makeHoliday("Día del Trabajo", month: 5, day: 1, year: year,
                                description: "1 de Mayo")

        // Independencia
        holidays += makeHoliday("Día de la Independencia", month: 9, day: 16, year: year,
                                description: "16 de Septiembre",
                                extraMultiplier: 1.10)

        // Revolución Mexicana — tercer lunes de noviembre
        if let d = nthWeekday(.monday, n: 3, month: 11, year: year) {
            holidays.append(makeEvent("Revolución Mexicana", start: d, end: d,
                                     type: .holiday, description: "Día festivo oficial"))
        }

        // Navidad
        holidays += makeHoliday("Navidad", month: 12, day: 25, year: year,
                                description: "25 de Diciembre",
                                extraMultiplier: 1.10)

        // Día de Muertos (no es festivo oficial pero impacta turismo)
        if let start = makeDate(year: year, month: 11, day: 1),
           let end   = makeDate(year: year, month: 11, day: 2) {
            holidays.append(makeEvent("Día de Muertos", start: start, end: end,
                                     type: .holiday,
                                     description: "1 y 2 de Noviembre",
                                     extraMultiplier: 1.05))
        }

        // Nochebuena (impacto turístico)
        holidays += makeHoliday("Nochebuena", month: 12, day: 24, year: year,
                                description: "24 de Diciembre",
                                extraMultiplier: 1.05)

        // Nochevieja
        holidays += makeHoliday("Nochevieja / Año Nuevo", month: 12, day: 31, year: year,
                                description: "31 de Diciembre",
                                extraMultiplier: 1.10)

        return holidays
    }

    // MARK: - School Vacations (SEP)

    private func schoolVacations(year: Int) -> [CalendarEvent] {
        var vacations: [CalendarEvent] = []

        // Semana Santa — 2 semanas centradas en Pascua
        let easter       = easterDate(year: year)
        let santaStart   = cal.date(byAdding: .day, value: -10, to: easter)!
        let santaEnd     = cal.date(byAdding: .day, value:   4, to: easter)!
        vacations.append(makeEvent("Semana Santa", start: santaStart, end: santaEnd,
                                   type: .vacation,
                                   description: "Vacaciones de Semana Santa",
                                   extraMultiplier: 1.15))

        // Vacaciones de verano — 1 julio al 31 agosto
        if let start = makeDate(year: year, month: 7, day: 1),
           let end   = makeDate(year: year, month: 8, day: 31) {
            vacations.append(makeEvent("Vacaciones de Verano", start: start, end: end,
                                       type: .vacation,
                                       description: "Julio y Agosto — Temporada Alta",
                                       extraMultiplier: 1.10))
        }

        // Vacaciones navideñas — 20 dic al 6 ene
        if let start = makeDate(year: year,   month: 12, day: 20),
           let end   = makeDate(year: year+1, month: 1,  day: 6) {
            vacations.append(makeEvent("Vacaciones de Navidad", start: start, end: end,
                                       type: .vacation,
                                       description: "Diciembre–Enero",
                                       extraMultiplier: 1.10))
        }

        // Puente de inicio de ciclo escolar (~19 agosto, una semana antes de regresar)
        if let start = makeDate(year: year, month: 8, day: 18),
           let end   = makeDate(year: year, month: 8, day: 25) {
            vacations.append(makeEvent("Último Fin de Vacaciones", start: start, end: end,
                                       type: .vacation,
                                       description: "Último fin de semana de verano"))
        }

        return vacations
    }

    // MARK: - Puentes (bridge days)

    private func puentes(year: Int) -> [CalendarEvent] {
        // Los días festivos con fecha fija generan puentes cuando caen martes o jueves
        let fixedHolidays: [(month: Int, day: Int, name: String)] = [
            (1,  1,  "Año Nuevo"),
            (5,  1,  "Día del Trabajo"),
            (9,  16, "Independencia"),
            (11, 1,  "Día de Muertos"),
            (11, 2,  "Día de Muertos"),
            (12, 12, "Virgen de Guadalupe"),
            (12, 24, "Nochebuena"),
            (12, 25, "Navidad"),
            (12, 31, "Fin de Año"),
        ]

        var bridges: [CalendarEvent] = []

        for h in fixedHolidays {
            guard let date = makeDate(year: year, month: h.month, day: h.day) else { continue }
            let weekday = cal.component(.weekday, from: date)   // 1=dom, 2=lun … 6=vie, 7=sab

            // Martes → lunes también es puente
            if weekday == 3 {
                let bridgeDay = cal.date(byAdding: .day, value: -1, to: date)!
                bridges.append(makeEvent("Puente \(h.name)", start: bridgeDay, end: date,
                                         type: .bridge,
                                         description: "Puente de \(h.name)"))
            }
            // Jueves → viernes también es puente
            if weekday == 5 {
                let bridgeDay = cal.date(byAdding: .day, value: 1, to: date)!
                bridges.append(makeEvent("Puente \(h.name)", start: date, end: bridgeDay,
                                         type: .bridge,
                                         description: "Puente de \(h.name)"))
            }
            // Miércoles → semana larga (lun-vier)
            if weekday == 4 {
                let bridgeStart = cal.date(byAdding: .day, value: -2, to: date)!
                let bridgeEnd   = cal.date(byAdding: .day, value:  2, to: date)!
                bridges.append(makeEvent("Puente largo \(h.name)", start: bridgeStart, end: bridgeEnd,
                                         type: .bridge,
                                         description: "Semana larga de \(h.name)",
                                         extraMultiplier: 1.05))
            }
        }

        return bridges
    }

    // MARK: - Weekends

    private func weekends(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        var current = startDate

        while current <= endDate {
            let weekday = cal.component(.weekday, from: current)
            // Sábado (7) → agregar sáb+dom
            if weekday == 7 {
                let sunday = cal.date(byAdding: .day, value: 1, to: current)!
                events.append(makeEvent("Fin de semana", start: current, end: sunday,
                                         type: .weekend,
                                         description: "Sábado y Domingo"))
                current = cal.date(byAdding: .day, value: 2, to: current)!
            } else {
                current = cal.date(byAdding: .day, value: 1, to: current)!
            }
        }
        return events
    }

    // MARK: - Easter (Algoritmo de Meeus/Jones/Butcher)

    private func easterDate(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day   = ((h + l - 7 * m + 114) % 31) + 1
        return makeDate(year: year, month: month, day: day) ?? Date()
    }

    // MARK: - Helpers

    private func yearsInRange(from: Date, to: Date) -> [Int] {
        let y1 = cal.component(.year, from: from)
        let y2 = cal.component(.year, from: to)
        return Array(Set(y1...y2)).sorted()
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date? {
        cal.date(from: DateComponents(year: year, month: month, day: day))
    }

    private func nthWeekday(_ weekday: Weekday, n: Int, month: Int, year: Int) -> Date? {
        var comps      = DateComponents()
        comps.year     = year
        comps.month    = month
        comps.weekday  = weekday.rawValue
        comps.weekdayOrdinal = n
        return cal.date(from: comps)
    }

    private func makeHoliday(_ name: String, month: Int, day: Int, year: Int,
                              description: String = "", extraMultiplier: Double = 1.0) -> [CalendarEvent] {
        guard let d = makeDate(year: year, month: month, day: day) else { return [] }
        return [makeEvent(name, start: d, end: d, type: .holiday,
                          description: description, extraMultiplier: extraMultiplier)]
    }

    private func makeEvent(_ name: String, start: Date, end: Date,
                           type: CalendarEventType,
                           description: String = "",
                           extraMultiplier: Double = 1.0) -> CalendarEvent {
        CalendarEvent(name: name, startDate: start, endDate: end,
                      type: type, extraMultiplier: extraMultiplier,
                      description: description)
    }

    private enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}
