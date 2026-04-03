//
//  NotificationsView.swift
//  InnSight
//
//  Vista de notificaciones del administrador
//

import SwiftUI
import Supabase

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let hotels: [Hotel]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Cargando notificaciones...")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                } else if let error = viewModel.errorMessage {
                    notificationErrorState(error)
                } else if viewModel.notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Leer todo") {
                            Task {
                                if let ownerId = await getOwnerId() {
                                    await viewModel.markAllAsRead(for: ownerId)
                                }
                            }
                        }
                        .font(AppFonts.labelMedium)
                        .accessibilityLabel("Marcar todas como leídas")
                    }
                }
            }
        }
        .task {
            if let ownerId = await getOwnerId() {
                await viewModel.fetchNotifications(for: ownerId)
            }
        }
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.notifications) { notification in
                    if notification.relatedReservationId != nil {
                        NavigationLink {
                            notificationDestination(for: notification)
                        } label: {
                            NotificationRowView(notification: notification)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            if !notification.isRead {
                                Task {
                                    await viewModel.markAsRead(notification.id)
                                }
                            }
                        })
                    } else {
                        NotificationRowView(notification: notification)
                            .onTapGesture {
                                if !notification.isRead {
                                    Task {
                                        await viewModel.markAsRead(notification.id)
                                    }
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            if let ownerId = await getOwnerId() {
                await viewModel.fetchNotifications(for: ownerId)
            }
        }
    }
    
    // MARK: - Notification Destination
    
    @ViewBuilder
    private func notificationDestination(for notification: AdminNotification) -> some View {
        // Navigate to the reservations list where the user can find the related reservation
        AdminReservationsView(hotels: hotels)
    }
    
    // MARK: - Error State
    
    private func notificationErrorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            
            Text(message)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Reintentar") {
                Task {
                    if let ownerId = await getOwnerId() {
                        await viewModel.fetchNotifications(for: ownerId)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .accessibilityLabel("Reintentar carga de notificaciones")
        }
        .padding(40)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin notificaciones")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Las notificaciones de nuevas reservaciones y cancelaciones aparecerán aquí")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sin notificaciones. Las notificaciones de nuevas reservaciones y cancelaciones aparecerán aquí.")
    }
    
    // MARK: - Helper
    
    private func getOwnerId() async -> UUID? {
        do {
            let session = try await supabase.auth.session
            return session.user.id
        } catch {
            print("❌ Error getting session:", error)
            return nil
        }
    }
}
