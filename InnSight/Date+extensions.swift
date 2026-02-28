//
//  Date+Extensions.swift
//  InnSight
//
//  Extensiones útiles para Date
//

import Foundation

extension Date {
    
    // MARK: - Formatting
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: self)
    }
    
    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: self)
    }
    
    func formattedLong() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd 'de' MMMM 'de' yyyy"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: self)
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    // MARK: - Date Calculations
    func addDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func addMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return abs(components.day ?? 0)
    }
    
    // MARK: - Comparisons
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    func isPast() -> Bool {
        self < Date()
    }
    
    func isFuture() -> Bool {
        self > Date()
    }
    
    // MARK: - Start/End of Day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    // MARK: - Relative Formatting
    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension String {
    
    // MARK: - Date from String
    func toDate(format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.date(from: self)
    }
    
    func toDateISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}
