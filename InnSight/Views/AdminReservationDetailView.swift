//
//  AdminReservationDetailView.swift
//  InnSight
//
//  Vista de detalle de reservación para el administrador
//

import SwiftUI

struct AdminReservationDetailView: View {
    let reservation: AdminReservation
    @ObservedObject var viewModel: AdminReservationsViewModel
    @StateObject private var commentService = CommentService()
    
    @Environment(\.dismiss) private var dismiss
    @State private var showStatusConfirmation = false
    @State private var pendingStatus: ReservationStatus?
    @State private var showSuccessMessage = false
    
    private var validTransitions: [ReservationStatus] {
        AdminReservationsViewModel.validNextStatuses(for: reservation.status)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Header
                statusHeader
                
                // Reservation Info
                infoSection
                
                // Guest Info
                guestSection
                
                // Room Info
                roomSection
                
                // Special Requests
                if let requests = reservation.specialRequests, !requests.isEmpty {
                    specialRequestsSection(requests)
                }
                
                // Comment Section
                commentSection
                
                // Status Actions
                if !validTransitions.isEmpty {
                    statusActionsSection
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Detalle de Reservación")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await commentService.fetchCommentAsAdmin(for: reservation.id)
        }
        .alert("Cambiar Estado", isPresented: $showStatusConfirmation) {
            Button("Cancelar", role: .cancel) {
                pendingStatus = nil
            }
            Button("Confirmar") {
                if let status = pendingStatus {
                    Task {
                        let success = await viewModel.updateReservationStatus(reservation.id, status: status)
                        if success {
                            showSuccessMessage = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }
                }
            }
        } message: {
            if let status = pendingStatus {
                Text("¿Cambiar el estado a \"\(status.displayName)\"?")
            }
        }
        .overlay {
            if showSuccessMessage {
                successOverlay
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        HStack {
            Image(systemName: reservation.status.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Estado actual")
                    .font(AppFonts.caption)
                    .foregroundColor(statusColor.opacity(0.8))
                Text(reservation.status.displayName)
                    .font(AppFonts.titleMedium)
            }
            
            Spacer()
            
            Text("#\(reservation.id.uuidString.prefix(8))")
                .font(AppFonts.caption)
                .foregroundColor(statusColor.opacity(0.7))
        }
        .foregroundColor(statusColor)
        .padding(16)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Información de Reservación")
            
            detailRow(icon: "calendar", label: "Check-in", value: reservation.startDate.formattedLong())
            detailRow(icon: "calendar.badge.checkmark", label: "Check-out", value: reservation.endDate.formattedLong())
            detailRow(icon: "moon.stars", label: "Noches", value: reservation.nightsText)
            detailRow(icon: "dollarsign.circle", label: "Total", value: reservation.totalPriceFormatted)
            detailRow(icon: "clock", label: "Creada", value: reservation.createdAt.relativeFormatted())
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Guest Section
    
    private var guestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Huésped")
            
            detailRow(icon: "person", label: "Nombre", value: reservation.clientName)
            if let email = reservation.clientEmail {
                detailRow(icon: "envelope", label: "Email", value: email)
            }
            detailRow(icon: "person.2", label: "Huéspedes", value: reservation.guestCountText)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Room Section
    
    private var roomSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Habitación")
            
            detailRow(icon: "building.2", label: "Hotel", value: reservation.hotelName)
            detailRow(icon: "door.left.hand.closed", label: "Habitación", value: reservation.roomNumber)
            detailRow(icon: "bed.double", label: "Tipo", value: reservation.roomTypeDisplayName)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Special Requests
    
    private func specialRequestsSection(_ requests: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Solicitudes Especiales")
            
            Text(requests)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Status Actions
    
    private var statusActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Acciones")
            
            ForEach(validTransitions, id: \.self) { status in
                Button {
                    pendingStatus = status
                    showStatusConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: status.icon)
                        Text(actionLabel(for: status))
                            .font(AppFonts.labelLarge)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(actionColor(for: status))
                    .padding(14)
                    .background(actionColor(for: status).opacity(0.1))
                    .cornerRadius(10)
                }
                .accessibilityLabel(actionLabel(for: status))
                .accessibilityHint("Toca para cambiar el estado de la reservación")
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Comment Section
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Comentario del Huésped")
            
            if commentService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let comment = commentService.comment {
                VStack(alignment: .leading, spacing: 8) {
                    if let rating = comment.rating {
                        StarRatingView(rating: .constant(rating), isInteractive: false)
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
                Text("Sin comentarios")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.success)
            Text("Estado actualizado")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(32)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(radius: 20)
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.titleSmall)
            .foregroundColor(AppColors.textSecondary)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            
            Text(label)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var statusColor: Color {
        Color(hex: reservation.status.color)
    }
    
    private func actionLabel(for status: ReservationStatus) -> String {
        switch status {
        case .checkedIn: return "Registrar Check-in"
        case .checkedOut: return "Registrar Check-out"
        case .completed: return "Marcar como Completada"
        case .cancelled: return "Cancelar Reservación"
        default: return status.displayName
        }
    }
    
    private func actionColor(for status: ReservationStatus) -> Color {
        switch status {
        case .cancelled: return AppColors.error
        default: return AppColors.primary
        }
    }
}
