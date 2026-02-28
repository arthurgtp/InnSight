//
//  NotificationService.swift
//  InnSight
//
//  Servicio para gestionar notificaciones de administrador
//

import Foundation
import Supabase

class NotificationService {
    
    // MARK: - Fetch Notifications
    
    /// Fetches all notifications for an admin user, sorted by creation date (newest first)
    func fetchNotifications(for ownerId: UUID) async throws -> [AdminNotification] {
        let notifications: [AdminNotification] = try await supabase
            .from("admin_notifications")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return notifications
    }
    
    // MARK: - Fetch Unread Notifications
    
    /// Fetches only unread notifications for an admin user
    func fetchUnreadNotifications(for ownerId: UUID) async throws -> [AdminNotification] {
        let notifications: [AdminNotification] = try await supabase
            .from("admin_notifications")
            .select()
            .eq("owner_id", value: ownerId.uuidString)
            .eq("is_read", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return notifications
    }
    
    // MARK: - Get Unread Count
    
    /// Returns the count of unread notifications for an admin user
    func getUnreadCount(for ownerId: UUID) async throws -> Int {
        let notifications = try await fetchUnreadNotifications(for: ownerId)
        return notifications.count
    }
    
    // MARK: - Mark as Read
    
    /// Marks a single notification as read
    func markAsRead(_ notificationId: UUID) async throws {
        try await supabase
            .from("admin_notifications")
            .update(["is_read": true])
            .eq("notification_id", value: notificationId.uuidString)
            .execute()
    }
    
    // MARK: - Mark All as Read
    
    /// Marks all notifications for an admin user as read
    func markAllAsRead(for ownerId: UUID) async throws {
        try await supabase
            .from("admin_notifications")
            .update(["is_read": true])
            .eq("owner_id", value: ownerId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
    
    // MARK: - Create Notification
    
    /// Creates a new notification for an admin user
    func createNotification(_ notification: NewNotification) async throws {
        try await supabase
            .from("admin_notifications")
            .insert(notification)
            .execute()
    }
    
    // MARK: - Create New Reservation Notification
    
    /// Creates a notification for a new reservation
    func createNewReservationNotification(
        ownerId: UUID,
        reservationId: UUID,
        guestName: String,
        hotelName: String,
        roomNumber: String
    ) async throws {
        let notification = NewNotification(
            ownerId: ownerId,
            type: .newReservation,
            title: "Nueva Reservación",
            message: "\(guestName) ha reservado la habitación \(roomNumber) en \(hotelName)",
            relatedReservationId: reservationId
        )
        try await createNotification(notification)
    }
    
    // MARK: - Create Cancellation Notification
    
    /// Creates a notification for a cancelled reservation
    func createCancellationNotification(
        ownerId: UUID,
        reservationId: UUID,
        guestName: String,
        hotelName: String,
        roomNumber: String
    ) async throws {
        let notification = NewNotification(
            ownerId: ownerId,
            type: .cancellation,
            title: "Reservación Cancelada",
            message: "\(guestName) ha cancelado su reservación de la habitación \(roomNumber) en \(hotelName)",
            relatedReservationId: reservationId
        )
        try await createNotification(notification)
    }
    
    // MARK: - Delete Notification
    
    /// Deletes a notification
    func deleteNotification(_ notificationId: UUID) async throws {
        try await supabase
            .from("admin_notifications")
            .delete()
            .eq("notification_id", value: notificationId.uuidString)
            .execute()
    }
}
