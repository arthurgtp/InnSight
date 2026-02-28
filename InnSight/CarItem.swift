//
//  CartItem.swift
//  InnSight
//
//  Modelo para items en el carrito de reservaciones
//

import Foundation

struct CartItem: Identifiable, Equatable {
    let id: UUID
    let room: Room
    let hotel: Hotel
    let startDate: Date
    let endDate: Date
    let guestCount: Int
    let specialRequests: String?
    
    // MARK: - Computed Properties
    var nights: Int {
        startDate.daysBetween(endDate)
    }
    
    var totalPrice: Decimal {
        room.price * Decimal(nights)
    }
    
    var totalPriceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: totalPrice as NSDecimalNumber) ?? "$0.00"
    }
    
    var dateRangeFormatted: String {
        "\(startDate.formattedShort()) - \(endDate.formattedShort())"
    }
    
    var nightsText: String {
        nights == 1 ? "1 noche" : "\(nights) noches"
    }
    
    var guestsText: String {
        guestCount == 1 ? "1 huésped" : "\(guestCount) huéspedes"
    }
    
    // MARK: - Equatable
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Cart Summary
struct CartSummary {
    let items: [CartItem]
    
    var totalItems: Int {
        items.count
    }
    
    var totalNights: Int {
        items.reduce(0) { $0 + $1.nights }
    }
    
    var subtotal: Decimal {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var tax: Decimal {
        subtotal * 0.16 // 16% IVA
    }
    
    var serviceFee: Decimal {
        subtotal * 0.05 // 5% comisión de servicio
    }
    
    var total: Decimal {
        subtotal + tax + serviceFee
    }
    
    var subtotalFormatted: String {
        subtotal.toCurrency()
    }
    
    var taxFormatted: String {
        tax.toCurrency()
    }
    
    var serviceFeeFormatted: String {
        serviceFee.toCurrency()
    }
    
    var totalFormatted: String {
        total.toCurrency()
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

// MARK: - Decimal Extension
extension Decimal {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}
