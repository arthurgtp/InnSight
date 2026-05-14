//
//  ReservationViewModel.swift
//  InnSight
//
//  ViewModel para gestionar la creación de reservaciones
//

import Foundation
import Supabase
import Combine

/// Represents a booked date range for a room
struct BookedDateRange: Codable, Equatable {
    let startDate: Date
    let endDate: Date

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let startStr = try container.decode(String.self, forKey: .startDate)
        let endStr = try container.decode(String.self, forKey: .endDate)

        self.startDate = try BookedDateRange.parseDate(startStr, codingKey: .startDate)
        self.endDate   = try BookedDateRange.parseDate(endStr,   codingKey: .endDate)
    }

    /// Parses either "yyyy-MM-dd" (PostgreSQL date) or any ISO-8601 timestamp
    /// (PostgreSQL timestamptz) into a midnight-local Date.
    private static func parseDate(_ raw: String, codingKey: CodingKeys) throws -> Date {
        // Slice to first 10 chars so both "2026-05-02" and "2026-05-02T06:00:00Z"
        // become "2026-05-02". Then parse with the DEVICE'S local timezone —
        // NOT UTC — so "2026-05-02" means midnight May 2 locally, not midnight UTC
        // (which would shift the date by the UTC offset and break comparisons).
        let dateOnly = String(raw.prefix(10))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale     = Locale(identifier: "en_US_POSIX")
        // ⚠️  No explicit timeZone → uses system/local timezone. This is intentional.
        if let d = formatter.date(from: dateOnly) {
            return d  // already midnight local; no startOfDay conversion needed
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: [codingKey],
                  debugDescription: "Cannot parse date string: '\(raw)'")
        )
    }

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Check if a date falls within this booked range
    func contains(_ date: Date) -> Bool {
        let day = date.startOfDay
        return day >= startDate.startOfDay && day < endDate.startOfDay
    }
    
    /// Check if a date range overlaps with this booked range
    func overlaps(start: Date, end: Date) -> Bool {
        return start.startOfDay < endDate.startOfDay && end.startOfDay > startDate.startOfDay
    }
}

@MainActor
class ReservationViewModel: ObservableObject {
    
    // MARK: - Form State
    @Published var checkInDate: Date = Date()
    @Published var checkOutDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    @Published var guestCount: Int = 1
    @Published var specialRequests: String = ""

    // MARK: - Dynamic Pricing
    @Published var dynamicPriceInfo: DynamicPriceInfo?

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdReservation: Reservation?

    // MARK: - Availability State
    @Published var bookedRanges: [BookedDateRange] = []
    @Published var isLoadingAvailability = false

    // MARK: - Validation State
    @Published var dateError: String?
    @Published var guestError: String?

    // MARK: - Dependencies
    private let room: Room
    private let pricingService = DynamicPricingService.shared

    // MARK: - Init
    init(room: Room) {
        self.room = room
        // Calcular precio inicial con las fechas por defecto
        self.dynamicPriceInfo = DynamicPricingService.shared.effectivePriceInfo(
            basePrice: room.price,
            checkIn:   Date(),
            checkOut:  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
    }

    // MARK: - Recalculate Dynamic Price

    func recalculateDynamicPrice() {
        dynamicPriceInfo = pricingService.effectivePriceInfo(
            basePrice : room.price,
            checkIn   : checkInDate,
            checkOut  : checkOutDate
        )
    }
    
    // MARK: - Fetch Booked Dates
    
    /// Fetch all booked date ranges for this room.
    /// Uses a SECURITY DEFINER RPC function so any authenticated user can
    /// check availability regardless of RLS policies on the reservations table.
    func fetchBookedDates() async {
        isLoadingAvailability = true

        do {
            let ranges: [BookedDateRange] = try await supabase
                .rpc("get_room_booked_dates", params: ["p_room_id": room.id.uuidString])
                .execute()
                .value

            bookedRanges = ranges
            print("📅 Fechas reservadas cargadas: \(ranges.count) rangos")

            // Always advance to the nearest actually-available date pair.
            // The calendar button is disabled while this fetch runs, so the
            // user cannot have selected dates yet — safe to overwrite.
            adjustDatesToAvailable()

        } catch {
            print("❌ Error fetching booked dates:", error.localizedDescription)
            bookedRanges = []
        }

        isLoadingAvailability = false
    }
    
    /// Adjust check-in and check-out dates to the next available dates
    private func adjustDatesToAvailable() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let maxSearch = maximumCheckInDate
        
        // Find first available check-in date starting from today
        var foundValidRange = false
        var searchCheckIn = today
        
        while searchCheckIn <= maxSearch && !foundValidRange {
            // Skip if check-in date is booked
            if isDateBooked(searchCheckIn) {
                searchCheckIn = calendar.date(byAdding: .day, value: 1, to: searchCheckIn) ?? searchCheckIn
                continue
            }
            
            // Found a potential check-in, now find a valid check-out
            // Check-out must be at least 1 day after check-in
            let minCheckOut = calendar.date(byAdding: .day, value: 1, to: searchCheckIn) ?? searchCheckIn
            var searchCheckOut = minCheckOut
            let maxCheckOut = calendar.date(byAdding: .day, value: ReservationViewModel.maximumStayNights, to: searchCheckIn) ?? searchCheckIn
            
            while searchCheckOut <= maxCheckOut {
                // Check if this range is completely valid:
                // 1. Check-out date is not booked
                // 2. No bookings in between check-in and check-out
                if !isDateBooked(searchCheckOut) && !rangeContainsBookedDates(from: searchCheckIn, to: searchCheckOut) {
                    // Found a valid range!
                    checkInDate = searchCheckIn
                    checkOutDate = searchCheckOut
                    foundValidRange = true
                    print("📅 Fechas ajustadas - Check-in: \(searchCheckIn.formattedShort()), Check-out: \(searchCheckOut.formattedShort())")
                    break
                }
                
                // If there's a booking that starts before or on this checkout date,
                // we need to move to a new check-in after that booking ends
                if isDateBooked(searchCheckOut) || rangeContainsBookedDates(from: searchCheckIn, to: searchCheckOut) {
                    // This check-in won't work, move to next potential check-in
                    break
                }
                
                searchCheckOut = calendar.date(byAdding: .day, value: 1, to: searchCheckOut) ?? searchCheckOut
            }
            
            if !foundValidRange {
                // Move check-in to the day after the next booking ends
                searchCheckIn = findNextAvailableDateAfterBooking(from: searchCheckIn)
            }
        }
        
        if !foundValidRange {
            // Fallback: just use today and tomorrow (will show error in UI)
            checkInDate = today
            checkOutDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            print("⚠️ No se encontró un rango disponible, usando fechas por default")
        }
    }
    
    /// Find the next available date after any booking that overlaps with the given date
    private func findNextAvailableDateAfterBooking(from date: Date) -> Date {
        let calendar = Calendar.current
        
        // Find the booking that contains or starts after this date
        for range in bookedRanges.sorted(by: { $0.startDate < $1.startDate }) {
            if range.contains(date) || range.startDate >= date {
                // Return the day after this booking ends
                return range.endDate
            }
        }
        
        // No booking found, just move to next day
        return calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }
    
    /// Check if a range contains any booked dates
    private func rangeContainsBookedDates(from start: Date, to end: Date) -> Bool {
        bookedRanges.contains { $0.overlaps(start: start, end: end) }
    }
    
    /// Check if a specific date is booked
    func isDateBooked(_ date: Date) -> Bool {
        bookedRanges.contains { $0.contains(date) }
    }
    
    /// Check if the selected date range overlaps with any booking
    func hasOverlappingBooking() -> Bool {
        bookedRanges.contains { $0.overlaps(start: checkInDate, end: checkOutDate) }
    }
    
    /// Get the next available date after a given date
    func nextAvailableDate(after date: Date) -> Date {
        var currentDate = date.startOfDay
        let maxDate = maximumCheckInDate
        
        while currentDate <= maxDate {
            if !isDateBooked(currentDate) {
                return currentDate
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return date
    }
    
    // MARK: - Computed Properties
    
    var numberOfNights: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkInDate.startOfDay, to: checkOutDate.startOfDay)
        return max(components.day ?? 0, 0)
    }
    
    var totalPrice: Decimal {
        dynamicPriceInfo?.totalPrice ?? (room.price * Decimal(numberOfNights))
    }

    var totalPriceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: totalPrice as NSDecimalNumber) ?? "$0.00"
    }
    
    // Pure validation check - no side effects, safe to call during view rendering
    var isFormValid: Bool {
        areDatesValid && isGuestCountValid
    }
    
    var minimumCheckOutDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: checkInDate) ?? checkInDate
    }
    
    /// Maximum date allowed for check-in (1 year from today)
    var maximumCheckInDate: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }
    
    /// Maximum date allowed for check-out (1 year + 30 days from today)
    var maximumCheckOutDate: Date {
        Calendar.current.date(byAdding: .day, value: 30, to: maximumCheckInDate) ?? maximumCheckInDate
    }
    
    /// Maximum stay duration in nights
    static let maximumStayNights = 30
    
    // Pure computed properties for validation (no side effects)
    private var areDatesValid: Bool {
        let today = Date().startOfDay
        let checkIn = checkInDate.startOfDay
        let checkOut = checkOutDate.startOfDay
        let maxCheckIn = maximumCheckInDate.startOfDay
        
        return checkIn >= today && 
               checkIn <= maxCheckIn && 
               checkOut > checkIn && 
               numberOfNights <= ReservationViewModel.maximumStayNights
    }
    
    private var isGuestCountValid: Bool {
        guestCount >= 1 && guestCount <= room.capacity
    }
    
    // MARK: - Validation Methods (with side effects - update error messages)
    
    func validateDates() -> Bool {
        dateError = nil
        
        let today = Date().startOfDay
        let checkIn = checkInDate.startOfDay
        let checkOut = checkOutDate.startOfDay
        let maxCheckIn = maximumCheckInDate.startOfDay
        
        if checkIn < today {
            dateError = "La fecha de entrada debe ser hoy o posterior"
            return false
        }
        
        if checkIn > maxCheckIn {
            dateError = "La fecha de entrada no puede ser mayor a 1 año desde hoy"
            return false
        }
        
        if checkOut <= checkIn {
            dateError = "La fecha de salida debe ser posterior a la entrada"
            return false
        }
        
        if numberOfNights > ReservationViewModel.maximumStayNights {
            dateError = "La estancia máxima es de \(ReservationViewModel.maximumStayNights) noches"
            return false
        }
        
        // Check for overlapping bookings
        if hasOverlappingBooking() {
            dateError = "Las fechas seleccionadas no están disponibles"
            return false
        }
        
        return true
    }
    
    func validateGuestCount() -> Bool {
        guestError = nil
        
        if guestCount < 1 {
            guestError = "El número de huéspedes debe ser al menos 1"
            return false
        }
        
        if guestCount > room.capacity {
            guestError = "El número de huéspedes debe ser entre 1 y \(room.capacity)"
            return false
        }
        
        return true
    }
    
    func validateForm() -> Bool {
        let datesValid = validateDates()
        let guestsValid = validateGuestCount()
        return datesValid && guestsValid
    }
    
    // MARK: - Create Reservation
    
    /// Check if the room is available for the selected dates
    func checkAvailability() async -> Bool {
        do {
            let startDateStr = ISO8601DateFormatter().string(from: checkInDate.startOfDay)
            let endDateStr = ISO8601DateFormatter().string(from: checkOutDate.startOfDay)
            
            // Call the database function to check availability
            let result: Bool = try await supabase
                .rpc("is_room_available", params: [
                    "p_room_id": room.id.uuidString,
                    "p_start_date": String(startDateStr.prefix(10)),
                    "p_end_date": String(endDateStr.prefix(10))
                ])
                .execute()
                .value
            
            return result
        } catch {
            print("❌ Error checking availability:", error.localizedDescription)
            // If we can't check, let the database constraint handle it
            return true
        }
    }
    
    func createReservation() async -> Bool {
        guard validateForm() else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = supabase.auth.currentUser?.id else {
                errorMessage = "Debes iniciar sesión para hacer una reservación"
                isLoading = false
                return false
            }
            
            // Check availability first
            let isAvailable = await checkAvailability()
            if !isAvailable {
                errorMessage = "La habitación no está disponible para las fechas seleccionadas"
                isLoading = false
                return false
            }
            
            let request = ReservationRequest(
                roomId: room.id,
                clientId: userId,
                startDate: checkInDate,
                endDate: checkOutDate,
                totalPrice: totalPrice,
                guestCount: guestCount,
                specialRequests: specialRequests.isEmpty ? nil : specialRequests
            )
            
            let response: Reservation = try await supabase
                .from("reservations")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            createdReservation = response
            print("✅ Reservación creada:", response.id)
            isLoading = false
            return true
            
        } catch let error {
            // Check if it's a constraint violation (double booking)
            if error.localizedDescription.contains("no_overlapping_reservations") ||
               error.localizedDescription.contains("exclusion") {
                errorMessage = "La habitación ya está reservada para esas fechas. Por favor, selecciona otras fechas."
            } else {
                errorMessage = "Error al crear la reservación. Por favor, intenta de nuevo."
            }
            print("❌ Error creating reservation:", error.localizedDescription)
            isLoading = false
            return false
        }
    }
}
