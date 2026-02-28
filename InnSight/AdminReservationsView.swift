//
//  AdminReservationsView.swift
//  InnSight
//
//  Vista de lista de reservaciones para el administrador
//

import SwiftUI
import Supabase

struct AdminReservationsView: View {
    @StateObject private var viewModel = AdminReservationsViewModel()
    let hotels: [Hotel]
    
    @State private var showFilters = false
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
            
            // Filter panel
            if showFilters {
                AdminReservationFilterView(
                    selectedStatus: $viewModel.statusFilter,
                    selectedHotel: $viewModel.hotelFilter,
                    startDate: $viewModel.startDateFilter,
                    endDate: $viewModel.endDateFilter,
                    hotels: hotels,
                    onApply: {
                        withAnimation { showFilters = false }
                    },
                    onReset: {
                        viewModel.resetFilters()
                        withAnimation { showFilters = false }
                    }
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Content
            if viewModel.isLoading && viewModel.reservations.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.filteredReservations.isEmpty {
                emptyView
            } else {
                reservationsList
            }
        }
        .task {
            guard !hasLoadedInitialData else { return }
            hasLoadedInitialData = true
            await loadReservations()
        }
        .onAppear {
            guard hasLoadedInitialData else { return }
            Task { await loadReservations() }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack {
            Text("\(viewModel.filteredReservations.count) reservaciones")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFilters.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filtros")
                        .font(AppFonts.labelMedium)
                }
                .foregroundColor(viewModel.hasActiveFilters ? AppColors.primary : AppColors.textSecondary)
            }
            .accessibilityLabel("Mostrar filtros")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Reservations List
    
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredReservations) { reservation in
                    NavigationLink {
                        AdminReservationDetailView(
                            reservation: reservation,
                            viewModel: viewModel
                        )
                    } label: {
                        AdminReservationRowView(reservation: reservation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .refreshable {
            await loadReservations()
        }
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando reservaciones...")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            
            Text(message)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Reintentar") {
                Task { await loadReservations() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .accessibilityLabel("Reintentar carga de reservaciones")
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            Text(viewModel.hasActiveFilters ? "Sin resultados" : "No hay reservaciones")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(viewModel.hasActiveFilters
                 ? "Intenta ajustar los filtros para ver más resultados"
                 : "Las reservaciones de tus hoteles aparecerán aquí")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if viewModel.hasActiveFilters {
                Button("Limpiar filtros") {
                    viewModel.resetFilters()
                }
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.primary)
                .accessibilityLabel("Limpiar todos los filtros")
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.hasActiveFilters
            ? "Sin resultados. Intenta ajustar los filtros para ver más resultados."
            : "No hay reservaciones. Las reservaciones de tus hoteles aparecerán aquí.")
    }
    
    // MARK: - Helpers
    
    private func loadReservations() async {
        do {
            let session = try await supabase.auth.session
            await viewModel.fetchReservations(for: session.user.id)
        } catch is CancellationError {
            // View disappeared, ignore
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // URL request cancelled (tab switch), ignore
        } catch {
            print("❌ Error getting session:", error)
        }
    }
}
