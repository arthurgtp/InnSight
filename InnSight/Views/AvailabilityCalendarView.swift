//
//  AvailabilityCalendarView.swift
//  InnSight
//
//  Calendario personalizado que muestra fechas disponibles/no disponibles
//

import SwiftUI

struct AvailabilityCalendarView: View {
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    let bookedRanges: [BookedDateRange]
    let maximumDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectionMode: SelectionMode = .checkIn
    @State private var tempCheckIn: Date?
    @State private var tempCheckOut: Date?
    @State private var currentMonth: Date = Date()
    
    private let maxNights = 30
    
    enum SelectionMode {
        case checkIn, checkOut
    }
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectionHeader
                warningBanner
                legendView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Show 12 months
                        ForEach(0..<12, id: \.self) { monthOffset in
                            if let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: startOfCurrentMonth) {
                                monthView(for: monthDate)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                
                confirmButton
            }
            .background(AppColors.background)
            .navigationTitle("Seleccionar Fechas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            initializeAvailableDates()
        }
        // If booked ranges arrive while the calendar is already open (race
        // condition where the async fetch completes after the sheet was
        // presented), re-initialize so blocked dates are enforced immediately.
        .onChange(of: bookedRanges) { _, _ in
            initializeAvailableDates()
        }
    }
    
    // MARK: - Initialize with available dates
    private func initializeAvailableDates() {
        let today = calendar.startOfDay(for: Date())
        
        // Find first available check-in date
        var checkIn = today
        if isDateBooked(checkInDate) || checkInDate < today {
            checkIn = findNextAvailableDate(from: today)
        } else {
            checkIn = checkInDate
        }
        
        // Find first available check-out date (at least 1 night after check-in)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: checkIn) ?? checkIn
        var checkOut = nextDay
        
        // If the proposed checkout is booked or there's a booking between checkin and checkout
        if isDateBooked(checkOutDate) || checkOutDate <= checkIn || rangeContainsBookedDates(from: checkIn, to: checkOutDate) {
            checkOut = findNextAvailableCheckout(from: checkIn)
        } else {
            checkOut = checkOutDate
        }
        
        tempCheckIn = checkIn
        tempCheckOut = checkOut
    }
    
    private func findNextAvailableDate(from date: Date) -> Date {
        var current = date
        let maxSearch = calendar.date(byAdding: .year, value: 1, to: date) ?? date
        
        while current <= maxSearch {
            if !isDateBooked(current) {
                return current
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return date
    }
    
    private func findNextAvailableCheckout(from checkIn: Date) -> Date {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: checkIn) ?? checkIn
        var current = nextDay
        let maxSearch = calendar.date(byAdding: .day, value: maxNights, to: checkIn) ?? checkIn
        
        while current <= maxSearch {
            if !rangeContainsBookedDates(from: checkIn, to: current) {
                return current
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return nextDay
    }
    
    private var startOfCurrentMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Number of nights
    private var numberOfNights: Int {
        guard let checkIn = tempCheckIn, let checkOut = tempCheckOut else { return 0 }
        let components = calendar.dateComponents([.day], from: checkIn, to: checkOut)
        return max(components.day ?? 0, 0)
    }
    
    private var exceedsMaxNights: Bool {
        numberOfNights > maxNights
    }
    
    // Check if current selection has issues
    private var hasBookingConflict: Bool {
        guard let checkIn = tempCheckIn, let checkOut = tempCheckOut else { return false }
        return rangeContainsBookedDates(from: checkIn, to: checkOut)
    }
    
    private var checkInIsBooked: Bool {
        guard let checkIn = tempCheckIn else { return false }
        return isDateBooked(checkIn)
    }
    
    private var checkOutIsBooked: Bool {
        guard let checkOut = tempCheckOut else { return false }
        return isDateBooked(checkOut)
    }
    
    // MARK: - Warning Banner
    @ViewBuilder
    private var warningBanner: some View {
        if checkInIsBooked {
            errorBanner(
                icon: "calendar.badge.exclamationmark",
                message: "La fecha de entrada seleccionada no está disponible. Selecciona otra fecha."
            )
        } else if checkOutIsBooked {
            errorBanner(
                icon: "calendar.badge.exclamationmark", 
                message: "La fecha de salida seleccionada no está disponible. Selecciona otra fecha."
            )
        } else if hasBookingConflict {
            errorBanner(
                icon: "exclamationmark.triangle.fill",
                message: "Hay fechas reservadas dentro del rango seleccionado. Ajusta tus fechas."
            )
        } else if exceedsMaxNights {
            warningBannerView(
                icon: "exclamationmark.triangle.fill",
                message: "La estancia máxima es de \(maxNights) noches. Has seleccionado \(numberOfNights)."
            )
        }
    }
    
    private func errorBanner(icon: String, message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.error)
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.error)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.error.opacity(0.15))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    private func warningBannerView(icon: String, message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.warning)
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.warning)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warning.opacity(0.15))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    // MARK: - Selection Header
    private var selectionHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Entrada")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(tempCheckIn?.formattedShort() ?? "Seleccionar")
                    .font(.headline)
                    .foregroundColor(selectionMode == .checkIn ? AppColors.primary : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(selectionMode == .checkIn ? AppColors.primary.opacity(0.1) : AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectionMode == .checkIn ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .onTapGesture { selectionMode = .checkIn }
            
            Image(systemName: "arrow.right")
                .foregroundColor(AppColors.textTertiary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Salida")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(tempCheckOut?.formattedShort() ?? "Seleccionar")
                    .font(.headline)
                    .foregroundColor(selectionMode == .checkOut ? AppColors.primary : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(selectionMode == .checkOut ? AppColors.primary.opacity(0.1) : AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectionMode == .checkOut ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .onTapGesture { selectionMode = .checkOut }
        }
        .padding(16)
    }
    
    // MARK: - Legend
    private var legendView: some View {
        HStack(spacing: 20) {
            legendItem(color: AppColors.primary, text: "Seleccionado")
            legendItem(color: AppColors.primary.opacity(0.3), text: "Rango")
            legendItem(color: AppColors.error.opacity(0.5), text: "No disponible")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(text).font(.caption).foregroundColor(AppColors.textSecondary)
        }
    }

    
    // MARK: - Month View
    private func monthView(for monthDate: Date) -> some View {
        let monthKey = monthTitle(for: monthDate)
        let offset = firstWeekdayOffset(for: monthDate)
        let days = daysInMonth(for: monthDate)
        
        return VStack(spacing: 12) {
            // Month header
            Text(monthKey)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: columns, spacing: 8) {
                // Empty cells for offset
                ForEach(0..<offset, id: \.self) { index in
                    Text("")
                        .frame(height: 40)
                        .id("\(monthKey)-empty-\(index)")
                }
                
                // Day cells
                ForEach(days, id: \.self) { day in
                    dayCell(day: day, month: monthDate)
                        .id("\(monthKey)-day-\(day)")
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func firstWeekdayOffset(for monthDate: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    private func daysInMonth(for monthDate: Date) -> [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate) else { return [] }
        return Array(range)
    }
    
    // MARK: - Day Cell
    private func dayCell(day: Int, month: Date) -> some View {
        let date = dateFor(day: day, month: month)
        let isBooked = isDateBooked(date)
        let isPast = date < calendar.startOfDay(for: Date())
        let isBeyondMax = date > maximumDate
        let isBeforeCheckIn = selectionMode == .checkOut && tempCheckIn != nil && date <= tempCheckIn!
        let isDisabled = isBooked || isPast || isBeyondMax
        let isCheckIn = tempCheckIn != nil && calendar.isDate(date, inSameDayAs: tempCheckIn!)
        let isCheckOut = tempCheckOut != nil && calendar.isDate(date, inSameDayAs: tempCheckOut!)
        let isInRange = isDateInSelectedRange(date)
        
        // Check if selecting this date would create a range with booked dates
        let wouldOverlapBooked = selectionMode == .checkOut && tempCheckIn != nil && date > tempCheckIn! && rangeContainsBookedDates(from: tempCheckIn!, to: date)
        
        return Button {
            if !isDisabled && !wouldOverlapBooked {
                handleDaySelection(date)
            }
        } label: {
            Text("\(day)")
                .font(.system(size: 16, weight: isCheckIn || isCheckOut ? .bold : .regular))
                .foregroundColor(dayTextColor(isDisabled: isDisabled || wouldOverlapBooked, isSelected: isCheckIn || isCheckOut, isBeforeCheckIn: isBeforeCheckIn))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(dayBackground(isBooked: isBooked, isDisabled: isDisabled, isCheckIn: isCheckIn, isCheckOut: isCheckOut, isInRange: isInRange, wouldOverlap: wouldOverlapBooked))
                .clipShape(Circle())
        }
        .disabled(isDisabled || wouldOverlapBooked)
    }
    
    private func dateFor(day: Int, month: Date) -> Date {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        return calendar.date(from: components) ?? Date()
    }
    
    private func dayTextColor(isDisabled: Bool, isSelected: Bool, isBeforeCheckIn: Bool = false) -> Color {
        if isSelected {
            return .white
        } else if isDisabled || isBeforeCheckIn {
            return AppColors.textTertiary
        } else {
            return AppColors.textPrimary
        }
    }
    
    private func dayBackground(isBooked: Bool, isDisabled: Bool, isCheckIn: Bool, isCheckOut: Bool, isInRange: Bool, wouldOverlap: Bool = false) -> some View {
        Group {
            if isCheckIn || isCheckOut {
                Circle().fill(AppColors.primary)
            } else if isBooked || wouldOverlap {
                Circle().fill(AppColors.error.opacity(0.3))
            } else if isInRange {
                Circle().fill(AppColors.primary.opacity(0.2))
            } else {
                Circle().fill(Color.clear)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isDateBooked(_ date: Date) -> Bool {
        bookedRanges.contains { $0.contains(date) }
    }
    
    private func isDateInSelectedRange(_ date: Date) -> Bool {
        guard let checkIn = tempCheckIn, let checkOut = tempCheckOut else { return false }
        let day = calendar.startOfDay(for: date)
        return day > calendar.startOfDay(for: checkIn) && day < calendar.startOfDay(for: checkOut)
    }
    
    private func handleDaySelection(_ date: Date) {
        if selectionMode == .checkIn {
            tempCheckIn = date
            // If checkout is before or equal to new checkin, auto-set checkout to next day
            if let checkout = tempCheckOut, checkout <= date {
                tempCheckOut = calendar.date(byAdding: .day, value: 1, to: date)
            }
            // Auto-switch to checkout selection
            selectionMode = .checkOut
        } else {
            // Checkout mode
            guard let checkin = tempCheckIn else { return }
            
            // Checkout must be after checkin
            if date > checkin {
                // Check if range contains any booked dates
                if !rangeContainsBookedDates(from: checkin, to: date) {
                    tempCheckOut = date
                }
            } else {
                // If user taps a date before checkin while in checkout mode,
                // treat it as selecting a new checkin date
                tempCheckIn = date
                tempCheckOut = calendar.date(byAdding: .day, value: 1, to: date)
            }
        }
    }
    
    private func rangeContainsBookedDates(from start: Date, to end: Date) -> Bool {
        bookedRanges.contains { $0.overlaps(start: start, end: end) }
    }
    
    // MARK: - Confirm Button
    private var confirmButton: some View {
        VStack(spacing: 8) {
            // Show nights count
            if let _ = tempCheckIn, let _ = tempCheckOut {
                Text("\(numberOfNights) \(numberOfNights == 1 ? "noche" : "noches")")
                    .font(.subheadline)
                    .foregroundColor(exceedsMaxNights ? AppColors.error : AppColors.textSecondary)
            }
            
            Button {
                if let checkIn = tempCheckIn, let checkOut = tempCheckOut {
                    checkInDate = checkIn
                    checkOutDate = checkOut
                    dismiss()
                }
            } label: {
                Text("Confirmar Fechas")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSelectionValid ? AppColors.primary : AppColors.textTertiary)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
        }
        .padding(16)
        .background(AppColors.background)
    }
    
    private var isSelectionValid: Bool {
        guard let checkIn = tempCheckIn, let checkOut = tempCheckOut else { return false }
        let nights = calendar.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
        return checkOut > checkIn && 
               !isDateBooked(checkIn) &&
               !isDateBooked(checkOut) &&
               !rangeContainsBookedDates(from: checkIn, to: checkOut) &&
               nights <= maxNights
    }
}

#Preview {
    AvailabilityCalendarView(
        checkInDate: .constant(Date()),
        checkOutDate: .constant(Date().addDays(3)),
        bookedRanges: [
            BookedDateRange(startDate: Date().addDays(5), endDate: Date().addDays(8)),
            BookedDateRange(startDate: Date().addDays(15), endDate: Date().addDays(18))
        ],
        maximumDate: Date().addMonths(12)
    )
}
