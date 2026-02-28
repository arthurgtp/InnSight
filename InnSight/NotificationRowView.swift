//
//  NotificationRowView.swift
//  InnSight
//
//  Fila de notificación para la lista de notificaciones del administrador
//

import SwiftUI

struct NotificationRowView: View {
    let notification: AdminNotification
    
    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            Image(systemName: notification.type.icon)
                .font(.system(size: 20))
                .foregroundColor(notification.type.color)
                .frame(width: 40, height: 40)
                .background(notification.type.color.opacity(0.12))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(notification.isRead ? AppFonts.bodyMedium : AppFonts.labelLarge)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(notification.timeAgo)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Text(notification.message)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(14)
        .background(notification.isRead ? AppColors.surface : AppColors.primaryLight.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.type.displayName): \(notification.title). \(notification.message). \(notification.isRead ? "Leída" : "No leída")")
    }
}
