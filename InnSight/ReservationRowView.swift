//
//  ReservationRowView.swift
//  InnSight
//
//  Componente reutilizable para mostrar una reservación en lista
//

import SwiftUI

struct ReservationRowView: View {
    let reservation: Reservation
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Hotel name
                Text(reservation.hotelName ?? "Hotel")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                // Room info
                Text(roomInfo)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                
                // Date range
                Text(reservation.dateRangeFormatted)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Right side: status badge and price
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge
                
                Text(reservation.totalPriceFormatted)
                    .font(AppFonts.labelLarge)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Subviews
    
    private var roomInfo: String {
        let number = reservation.roomNumber ?? ""
        let type = reservation.roomType ?? ""
        if !number.isEmpty && !type.isEmpty {
            return "Hab. \(number) • \(type)"
        } else if !number.isEmpty {
            return "Hab. \(number)"
        } else if !type.isEmpty {
            return type
        }
        return "Habitación"
    }
    
    private var statusIcon: some View {
        Image(systemName: reservation.status.icon)
            .font(.system(size: 24))
            .foregroundColor(Color(hex: reservation.status.color))
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(Color(hex: reservation.status.color).opacity(0.15))
            )
    }
    
    private var statusBadge: some View {
        Text(reservation.status.displayName)
            .font(AppFonts.labelSmall)
            .foregroundColor(Color(hex: reservation.status.color))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: reservation.status.color).opacity(0.15))
            )
    }
}

#Preview {
    List {
        ReservationRowView(reservation: Reservation(
            id: UUID(),
            roomId: UUID(),
            clientId: UUID(),
            hotelName: "Hotel Playa del Carmen",
            roomNumber: "101",
            roomType: "Suite Deluxe",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            status: .confirmed,
            totalPrice: 4500.00,
            guestCount: 2,
            specialRequests: nil,
            checkInTime: nil,
            checkOutTime: nil,
            createdAt: Date()
        ))
        
        ReservationRowView(reservation: Reservation(
            id: UUID(),
            roomId: UUID(),
            clientId: UUID(),
            hotelName: "Hotel Centro Histórico",
            roomNumber: "205",
            roomType: "Doble",
            startDate: Date().addingTimeInterval(-86400 * 10),
            endDate: Date().addingTimeInterval(-86400 * 7),
            status: .completed,
            totalPrice: 2800.00,
            guestCount: 2,
            specialRequests: nil,
            checkInTime: nil,
            checkOutTime: nil,
            createdAt: Date()
        ))
        
        ReservationRowView(reservation: Reservation(
            id: UUID(),
            roomId: UUID(),
            clientId: UUID(),
            hotelName: "Hotel Reforma",
            roomNumber: "312",
            roomType: "Individual",
            startDate: Date().addingTimeInterval(86400 * 5),
            endDate: Date().addingTimeInterval(86400 * 7),
            status: .cancelled,
            totalPrice: 1500.00,
            guestCount: 1,
            specialRequests: nil,
            checkInTime: nil,
            checkOutTime: nil,
            createdAt: Date()
        ))
    }
}
