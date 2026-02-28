//
//  AdminReservationRowView.swift
//  InnSight
//
//  Fila de reservación para la lista de administrador
//

import SwiftUI

struct AdminReservationRowView: View {
    let reservation: AdminReservation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Hotel + Status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reservation.hotelName)
                        .font(AppFonts.titleSmall)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("Hab. \(reservation.roomNumber) · \(reservation.roomTypeDisplayName)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
                .background(AppColors.divider)
            
            // Middle: Guest + Dates
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.caption2)
                        Text(reservation.clientName)
                            .font(AppFonts.bodyMedium)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(reservation.dateRangeFormatted)
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(reservation.totalPriceFormatted)
                        .font(AppFonts.titleSmall)
                        .foregroundColor(AppColors.primary)
                    
                    Text(reservation.nightsText)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reservation.hotelName), habitación \(reservation.roomNumber), huésped \(reservation.clientName), \(reservation.status.displayName), \(reservation.totalPriceFormatted)")
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: reservation.status.icon)
                .font(.caption2)
            Text(reservation.status.displayName)
                .font(AppFonts.labelSmall)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.12))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        Color(hex: reservation.status.color)
    }
}
