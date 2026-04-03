//
//  ReservationHistoryView.swift
//  InnSight
//
//  Vista de historial de reservaciones del usuario
//

import SwiftUI

struct ReservationHistoryView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.reservations.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                VStack(spacing: 0) {
                    filterPicker
                    
                    if viewModel.filteredReservations.isEmpty {
                        emptyStateView
                    } else {
                        reservationsList
                    }
                }
            }
        }
        .navigationTitle("Reservaciones")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Filter Picker
    
    private var filterPicker: some View {
        Picker("Filtro", selection: $viewModel.selectedFilter) {
            ForEach(ReservationFilter.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
    }
    
    // MARK: - Reservations List
    
    private var reservationsList: some View {
        List {
            ForEach(viewModel.filteredReservations) { reservation in
                NavigationLink {
                    ReservationDetailView(reservation: reservation)
                        .environmentObject(viewModel)
                } label: {
                    ReservationRowView(reservation: reservation)
                }
                .listRowBackground(AppColors.surface)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.fetchReservations()
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text(emptyStateTitle)
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(emptyStateMessage)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State Helpers
    
    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case .all: return "calendar.badge.exclamationmark"
        case .active: return "clock"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .all: return "Sin reservaciones"
        case .active: return "Sin reservaciones activas"
        case .completed: return "Sin reservaciones completadas"
        case .cancelled: return "Sin reservaciones canceladas"
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .all: return "Aún no tienes reservaciones. ¡Explora nuestros hoteles y haz tu primera reservación!"
        case .active: return "No tienes reservaciones activas en este momento."
        case .completed: return "No tienes reservaciones completadas aún."
        case .cancelled: return "No tienes reservaciones canceladas."
        }
    }
}

#Preview {
    NavigationView {
        ReservationHistoryView()
            .environmentObject(ProfileViewModel())
    }
}
