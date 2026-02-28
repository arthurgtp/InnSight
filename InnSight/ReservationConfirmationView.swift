//
//  ReservationConfirmationView.swift
//  InnSight
//
//  Vista de confirmación de reservación exitosa
//

import SwiftUI

struct ReservationConfirmationView: View {
    let reservation: Reservation
    let hotel: Hotel
    let room: Room
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAnimation = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon with Animation
                    successIcon
                    
                    // Success Message
                    successMessage
                    
                    // Reservation Details Card
                    reservationDetailsCard
                    
                    // Back to Home Button
                    backToHomeButton
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showSuccessAnimation = true
            }
        }
    }
    
    // MARK: - Success Icon
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.success.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(showSuccessAnimation ? 1 : 0.5)
            
            Circle()
                .fill(AppColors.success.opacity(0.3))
                .frame(width: 90, height: 90)
                .scaleEffect(showSuccessAnimation ? 1 : 0.5)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.success)
                .scaleEffect(showSuccessAnimation ? 1 : 0)
                .rotationEffect(.degrees(showSuccessAnimation ? 0 : -90))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Success Message
    private var successMessage: some View {
        VStack(spacing: 8) {
            Text("¡Reservación Confirmada!")
                .appHeadlineMedium()
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Tu reservación ha sido procesada exitosamente")
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    
    // MARK: - Reservation Details Card
    private var reservationDetailsCard: some View {
        VStack(spacing: 0) {
            // Header with Status Badge
            HStack {
                Text("Detalles de la Reservación")
                    .appTitleMedium()
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Status Badge
                statusBadge
            }
            .padding(16)
            .background(AppColors.surface)
            
            Divider()
                .background(AppColors.divider)
            
            // Details
            VStack(spacing: 16) {
                // Hotel
                detailRow(
                    icon: "building.2",
                    title: "Hotel",
                    value: hotel.name
                )
                
                // Room
                detailRow(
                    icon: "bed.double",
                    title: "Habitación",
                    value: "\(room.roomType.displayName) - #\(room.roomNumber)"
                )
                
                Divider()
                    .background(AppColors.divider)
                
                // Check-in Date
                detailRow(
                    icon: "calendar",
                    title: "Fecha de entrada",
                    value: reservation.startDate.formattedLong()
                )
                
                // Check-out Date
                detailRow(
                    icon: "calendar.badge.checkmark",
                    title: "Fecha de salida",
                    value: reservation.endDate.formattedLong()
                )
                
                // Nights
                detailRow(
                    icon: "moon.stars",
                    title: "Noches",
                    value: reservation.nightsText
                )
                
                Divider()
                    .background(AppColors.divider)
                
                // Guests
                detailRow(
                    icon: "person.2",
                    title: "Huéspedes",
                    value: "\(reservation.guestCount ?? 1)"
                )
                
                // Special Requests (if any)
                if let specialRequests = reservation.specialRequests, !specialRequests.isEmpty {
                    detailRow(
                        icon: "text.bubble",
                        title: "Solicitudes especiales",
                        value: specialRequests
                    )
                }
                
                Divider()
                    .background(AppColors.divider)
                
                // Total Price
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "creditcard")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        Text("Total")
                            .appTitleMedium()
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(reservation.totalPriceFormatted)
                        .appHeadlineSmall()
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(16)
            .background(AppColors.surface)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: reservation.status.icon)
                .font(.caption)
            Text(reservation.status.displayName)
                .appLabelSmall()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: reservation.status.color))
        .cornerRadius(8)
    }
    
    // MARK: - Detail Row
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appBodySmall()
                    .foregroundColor(AppColors.textSecondary)
                
                Text(value)
                    .appBodyMedium()
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
    }

    
    // MARK: - Back to Home Button
    private var backToHomeButton: some View {
        Button {
            // Post notification to dismiss all the way back to HotelsView
            NotificationCenter.default.post(name: .reservationCompleted, object: nil)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                Text("Volver al Inicio")
            }
            .appLabelLarge()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primary)
            .cornerRadius(12)
        }
        .accessibilityLabel("Volver al inicio")
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ReservationConfirmationView(
            reservation: Reservation(
                id: UUID(),
                roomId: UUID(),
                clientId: UUID(),
                hotelName: "Hotel Paradise",
                roomNumber: "101",
                roomType: "suite",
                startDate: Date(),
                endDate: Date().addDays(3),
                status: .confirmed,
                totalPrice: 4500.00,
                guestCount: 2,
                specialRequests: "Llegada tardía después de las 10pm",
                checkInTime: nil,
                checkOutTime: nil,
                createdAt: Date()
            ),
            hotel: Hotel(
                id: UUID(),
                name: "Hotel Paradise",
                location: "Cancún, México",
                latitude: nil,
                longitude: nil,
                imageUrl: nil,
                description: nil,
                rating: 4.5,
                amenities: [],
                ownerId: UUID(),
                createdAt: Date()
            ),
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: "101",
                roomType: .suite,
                price: 1500.00,
                capacity: 4,
                description: "Habitación amplia con vista al mar",
                amenities: ["WiFi", "TV", "Aire Acondicionado"],
                images: [],
                isActive: true,
                createdAt: Date()
            )
        )
    }
}
