//
//  QuickActionsView.swift
//  InnSight
//
//  Componente de acciones rápidas para el dashboard de administrador
//

import SwiftUI

// MARK: - Quick Action Model

struct QuickAction: Identifiable {
    let id = UUID()
    let type: QuickActionType
    let title: String
    let icon: String
    let color: Color
    
    static let defaultActions: [QuickAction] = [
        QuickAction(
            type: .addHotel,
            title: "Agregar Hotel",
            icon: "building.2.fill",
            color: AppColors.primary
        ),
        QuickAction(
            type: .addRoom,
            title: "Agregar Habitación",
            icon: "bed.double.circle",
            color: AppColors.secondary
        ),
        QuickAction(
            type: .viewReservations,
            title: "Ver Reservaciones",
            icon: "calendar.badge.clock",
            color: AppColors.success
        ),
        QuickAction(
            type: .viewAnalytics,
            title: "Ver Analíticas",
            icon: "chart.bar.fill",
            color: AppColors.accent
        )
    ]
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    let actions: [QuickAction]
    let onAction: (QuickAction) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acciones Rápidas")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(actions) { action in
                    QuickActionButton(action: action) {
                        onAction(action)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(action.color)
                
                Text(action.title)
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(action.title)
        .accessibilityHint(accessibilityHintText)
    }
    
    private var accessibilityHintText: String {
        switch action.type {
        case .addHotel:
            return "Toca para agregar un nuevo hotel"
        case .addRoom:
            return "Toca para agregar una nueva habitación"
        case .viewReservations:
            return "Toca para ver todas las reservaciones"
        case .viewAnalytics:
            return "Toca para ver las analíticas"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        QuickActionsView(actions: QuickAction.defaultActions) { action in
            print("Tapped: \(action.title)")
        }
        .padding()
    }
}
