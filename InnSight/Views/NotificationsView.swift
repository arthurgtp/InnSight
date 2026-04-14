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

    @State private var showDeleteAllAlert  = false
    @State private var showDeleteReadAlert = false

    let hotels: [Hotel]

    // Helpers
    private var hasRead: Bool   { viewModel.notifications.contains { $0.isRead } }
    private var hasAny:  Bool   { !viewModel.notifications.isEmpty }

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
                    Button("Cerrar") { dismiss() }
                }

                if hasAny {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            // Marcar todo como leído
                            if viewModel.unreadCount > 0 {
                                Button {
                                    Task {
                                        if let id = await getOwnerId() {
                                            await viewModel.markAllAsRead(for: id)
                                        }
                                    }
                                } label: {
                                    Label("Marcar todo como leído", systemImage: "checkmark.circle")
                                }
                            }

                            // Eliminar leídas
                            if hasRead {
                                Button(role: .destructive) {
                                    showDeleteReadAlert = true
                                } label: {
                                    Label("Eliminar leídas", systemImage: "trash")
                                }
                            }

                            // Eliminar todo
                            Button(role: .destructive) {
                                showDeleteAllAlert = true
                            } label: {
                                Label("Eliminar todo", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 17))
                                .accessibilityLabel("Opciones de notificaciones")
                        }
                    }
                }
            }
            // Confirm: eliminar leídas
            .alert("Eliminar notificaciones leídas", isPresented: $showDeleteReadAlert) {
                Button("Eliminar", role: .destructive) {
                    Task {
                        if let id = await getOwnerId() {
                            await viewModel.deleteReadNotifications(for: id)
                        }
                    }
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Se eliminarán todas las notificaciones que ya leíste. Esta acción no se puede deshacer.")
            }
            // Confirm: eliminar todo
            .alert("Eliminar todas las notificaciones", isPresented: $showDeleteAllAlert) {
                Button("Eliminar todo", role: .destructive) {
                    Task {
                        if let id = await getOwnerId() {
                            await viewModel.deleteAllNotifications(for: id)
                        }
                    }
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Se eliminarán todas las notificaciones. Esta acción no se puede deshacer.")
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
        List {
            ForEach(viewModel.notifications) { notification in
                Group {
                    if notification.relatedReservationId != nil {
                        NavigationLink {
                            notificationDestination(for: notification)
                        } label: {
                            NotificationRowView(notification: notification)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            if !notification.isRead {
                                Task { await viewModel.markAsRead(notification.id) }
                            }
                        })
                    } else {
                        NotificationRowView(notification: notification)
                            .onTapGesture {
                                if !notification.isRead {
                                    Task { await viewModel.markAsRead(notification.id) }
                                }
                            }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteNotification(notification.id) }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if !notification.isRead {
                        Button {
                            Task { await viewModel.markAsRead(notification.id) }
                        } label: {
                            Label("Leída", systemImage: "checkmark.circle")
                        }
                        .tint(AppColors.primary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
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
