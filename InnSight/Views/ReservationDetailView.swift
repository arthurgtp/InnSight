//
//  ReservationDetailView.swift
//  InnSight
//
//  Vista de detalle completo de una reservación
//

import SwiftUI

struct ReservationDetailView: View {
    let reservation: Reservation
    @EnvironmentObject var viewModel: ProfileViewModel
    @StateObject private var commentService = CommentService()
    @State private var showCancelAlert = false
    @State private var isCancelling = false
    @State private var commentText = ""
    @State private var selectedRating: Int = 0
    @State private var isSubmittingComment = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                roomSection
                datesSection
                guestsSection
                
                if let specialRequests = reservation.specialRequests, !specialRequests.isEmpty {
                    specialRequestsSection(specialRequests)
                }
                
                priceSection
                
                if reservation.status == .completed || reservation.status == .cancelled {
                    commentSection
                }
                
                if reservation.canBeCancelled {
                    cancelButton
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .onAppear {
            if reservation.status == .completed || reservation.status == .cancelled {
                Task {
                    await commentService.fetchComment(for: reservation.id)
                }
            }
        }
        .navigationTitle("Detalle de Reservación")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancelar Reservación", isPresented: $showCancelAlert) {
            Button("No", role: .cancel) { }
            Button("Sí, cancelar", role: .destructive) {
                cancelReservation()
            }
        } message: {
            Text("¿Estás seguro de que deseas cancelar esta reservación? Esta acción no se puede deshacer.")
        }
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        DetailSection(title: "Comentario", icon: "text.bubble") {
            if commentService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let comment = commentService.comment {
                // Read-only existing comment
                VStack(alignment: .leading, spacing: 8) {
                    if let rating = comment.rating {
                        HStack(spacing: 8) {
                            Text("Evaluación")
                                .font(AppFonts.labelMedium)
                                .foregroundColor(AppColors.textSecondary)
                            StarRatingView(rating: .constant(rating), isInteractive: false)
                        }
                    }
                    
                    Text(comment.commentText)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(comment.createdAt.formattedLong())
                        .font(AppFonts.labelSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                // Comment input
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Evaluación")
                            .font(AppFonts.labelMedium)
                            .foregroundColor(AppColors.textSecondary)
                        StarRatingView(rating: $selectedRating, isInteractive: true)
                    }
                    
                    TextEditor(text: $commentText)
                        .font(AppFonts.bodyMedium)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(AppColors.inputBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.inputBorder, lineWidth: 1)
                        )
                    
                    if let errorMessage = commentService.errorMessage {
                        Text(errorMessage)
                            .font(AppFonts.labelSmall)
                            .foregroundColor(AppColors.error)
                    }
                    
                    Button {
                        submitComment()
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmittingComment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Enviar Comentario")
                            }
                        }
                        .font(AppFonts.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                    }
                    .disabled(isSubmittingComment)
                }
            }
        }
    }
    
    private func submitComment() {
        isSubmittingComment = true
        Task {
            let success = await commentService.submitComment(reservationId: reservation.id, text: commentText, rating: selectedRating)
            await MainActor.run {
                isSubmittingComment = false
                if success {
                    commentText = ""
                    selectedRating = 0
                }
            }
        }
    }
    
    // MARK: - Cancel Action
    
    private func cancelReservation() {
        let reservationId = reservation.id.uuidString
        isCancelling = true
        
        Task {
            let success = await viewModel.cancelReservation(reservationId)
            await MainActor.run {
                isCancelling = false
                if success {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Cancel Button
    
    private var cancelButton: some View {
        Button {
            showCancelAlert = true
        } label: {
            HStack(spacing: 8) {
                if isCancelling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancelar Reservación")
                }
            }
            .font(AppFonts.labelLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.error)
            .cornerRadius(12)
        }
        .disabled(isCancelling)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(reservation.hotelName ?? "Hotel")
                .font(AppFonts.headlineSmall)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            statusBadge
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: reservation.status.icon)
                .font(.system(size: 14))
            Text(reservation.status.displayName)
                .font(AppFonts.labelMedium)
        }
        .foregroundColor(Color(hex: reservation.status.color))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(hex: reservation.status.color).opacity(0.15))
        )
    }
    
    // MARK: - Room Section
    
    private var roomSection: some View {
        DetailSection(title: "Habitación", icon: "bed.double") {
            VStack(alignment: .leading, spacing: 8) {
                if let roomNumber = reservation.roomNumber {
                    DetailRow(label: "Número", value: roomNumber)
                }
                if let roomType = reservation.roomType {
                    DetailRow(label: "Tipo", value: roomType)
                }
            }
        }
    }
    
    // MARK: - Dates Section
    
    private var datesSection: some View {
        DetailSection(title: "Fechas", icon: "calendar") {
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Entrada", value: reservation.startDate.formattedLong())
                DetailRow(label: "Salida", value: reservation.endDate.formattedLong())
                DetailRow(label: "Duración", value: reservation.nightsText)
            }
        }
    }
    
    // MARK: - Guests Section
    
    private var guestsSection: some View {
        DetailSection(title: "Huéspedes", icon: "person.2") {
            let count = reservation.guestCount ?? 1
            DetailRow(label: "Cantidad", value: count == 1 ? "1 huésped" : "\(count) huéspedes")
        }
    }
    
    // MARK: - Special Requests Section
    
    private func specialRequestsSection(_ requests: String) -> some View {
        DetailSection(title: "Solicitudes Especiales", icon: "text.bubble") {
            Text(requests)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        VStack(spacing: 8) {
            Text("Total")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text(reservation.totalPriceFormatted)
                .font(AppFonts.headlineLarge)
                .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Detail Section Component

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
                
                Text(title)
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReservationDetailView(reservation: Reservation(
            id: UUID(),
            roomId: UUID(),
            clientId: UUID(),
            hotelName: "Hotel Playa del Carmen",
            roomNumber: "101",
            roomType: "Suite Deluxe",
            startDate: Date().addingTimeInterval(86400),
            endDate: Date().addingTimeInterval(86400 * 3),
            status: .confirmed,
            totalPrice: 4500.00,
            guestCount: 2,
            specialRequests: "Cama king size, vista al mar",
            checkInTime: nil,
            checkOutTime: nil,
            createdAt: Date()
        ))
        .environmentObject(ProfileViewModel())
    }
}
