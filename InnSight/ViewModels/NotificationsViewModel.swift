//
//  NotificationsViewModel.swift
//  InnSight
//
//  ViewModel para gestión de notificaciones del administrador
//

import Foundation
import Combine
import Supabase

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AdminNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let notificationService = NotificationService()
    
    // MARK: - Fetch Notifications
    
    func fetchNotifications(for ownerId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await notificationService.fetchNotifications(for: ownerId)
            notifications = fetched
            unreadCount = fetched.filter { !$0.isRead }.count
        } catch is CancellationError {
            print("⚠️ Notifications fetch was cancelled")
        } catch {
            errorMessage = "Error al cargar notificaciones: \(error.localizedDescription)"
            print("❌ Error fetching notifications:", error)
        }
        
        isLoading = false
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(_ notificationId: UUID) async {
        do {
            try await notificationService.markAsRead(notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId && !$0.isRead }) {
                let old = notifications[index]
                notifications[index] = AdminNotification(
                    id: old.id,
                    ownerId: old.ownerId,
                    type: old.type,
                    title: old.title,
                    message: old.message,
                    relatedReservationId: old.relatedReservationId,
                    isRead: true,
                    createdAt: old.createdAt
                )
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            print("❌ Error marking notification as read:", error)
        }
    }
    
    // MARK: - Mark All as Read
    
    func markAllAsRead(for ownerId: UUID) async {
        do {
            try await notificationService.markAllAsRead(for: ownerId)
            
            // Update local state
            notifications = notifications.map { notification in
                guard !notification.isRead else { return notification }
                return AdminNotification(
                    id: notification.id,
                    ownerId: notification.ownerId,
                    type: notification.type,
                    title: notification.title,
                    message: notification.message,
                    relatedReservationId: notification.relatedReservationId,
                    isRead: true,
                    createdAt: notification.createdAt
                )
            }
            unreadCount = 0
        } catch {
            errorMessage = "Error al marcar notificaciones: \(error.localizedDescription)"
            print("❌ Error marking all as read:", error)
        }
    }
}
