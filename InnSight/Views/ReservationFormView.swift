//
//  ReservationFormView.swift
//  InnSight
//
//  Formulario para crear una reservación
//

import SwiftUI

struct ReservationFormView: View {
    let room: Room
    let hotel: Hotel
    @StateObject private var viewModel: ReservationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var showCalendar = false
    
    init(room: Room, hotel: Hotel) {
        self.room = room
        self.hotel = hotel
        _viewModel = StateObject(wrappedValue: ReservationViewModel(room: room))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Room Info Header
                        roomInfoHeader
                        
                        // Date Selection
                        dateSelectionSection
                        
                        // Guest Count
                        guestCountSection
                        
                        // Special Requests
                        specialRequestsSection
                        
                        // Price Summary
                        priceSummarySection
                        
                        // Confirm Button
                        confirmButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reservar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .navigationDestination(isPresented: $showConfirmation) {
                if let reservation = viewModel.createdReservation {
                    ReservationConfirmationView(
                        reservation: reservation,
                        hotel: hotel,
                        room: room
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .reservationCompleted)) { _ in
                // Dismiss the form sheet when reservation is completed
                dismiss()
            }
            .task {
                // Fetch booked dates when view appears
                await viewModel.fetchBookedDates()
            }
            .sheet(isPresented: $showCalendar) {
                AvailabilityCalendarView(
                    checkInDate: $viewModel.checkInDate,
                    checkOutDate: $viewModel.checkOutDate,
                    bookedRanges: viewModel.bookedRanges,
                    maximumDate: viewModel.maximumCheckInDate
                )
            }
        }
    }

    
    // MARK: - Room Info Header
    private var roomInfoHeader: some View {
        HStack(spacing: 16) {
            // Room Image
            if let mainImage = room.mainImage {
                AsyncImage(url: URL(string: mainImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surfaceSecondary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(AppColors.textTertiary)
                        }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(AppColors.surfaceSecondary)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .overlay {
                        Image(systemName: "bed.double")
                            .foregroundColor(AppColors.textTertiary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(room.roomType.displayName)
                    .appLabelSmall()
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.primary)
                    .cornerRadius(6)
                
                Text("Habitación \(room.roomNumber)")
                    .appTitleMedium()
                    .foregroundColor(AppColors.textPrimary)
                
                Text(hotel.name)
                    .appBodySmall()
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fechas de estancia")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            // Single button to open calendar
            Button {
                showCalendar = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.primary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.checkInDate.formattedShort()) - \(viewModel.checkOutDate.formattedShort())")
                            .appTitleMedium()
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(viewModel.numberOfNights) \(viewModel.numberOfNights == 1 ? "noche" : "noches")")
                            .appBodySmall()
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(16)
                .background(AppColors.inputBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Warning if dates overlap with booked dates
            if viewModel.hasOverlappingBooking() {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.warning)
                    Text("Las fechas seleccionadas no están disponibles. Toca para elegir otras fechas.")
                        .appBodySmall()
                        .foregroundColor(AppColors.warning)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.warning.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Date Error (other validation errors)
            if let dateError = viewModel.dateError, !viewModel.hasOverlappingBooking() {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(AppColors.error)
                    Text(dateError)
                        .appBodySmall()
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Loading indicator
            if viewModel.isLoadingAvailability {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Verificando disponibilidad...")
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .onChange(of: viewModel.checkInDate) { _, _ in
            Task { @MainActor in
                _ = viewModel.validateDates()
            }
        }
        .onChange(of: viewModel.checkOutDate) { _, _ in
            Task { @MainActor in
                _ = viewModel.validateDates()
            }
        }
    }

    
    // MARK: - Guest Count Section
    private var guestCountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Huéspedes")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                
                Text("Número de huéspedes")
                    .appBodyMedium()
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Stepper(
                    value: $viewModel.guestCount,
                    in: 1...room.capacity
                ) {
                    Text("\(viewModel.guestCount)")
                        .appTitleMedium()
                        .foregroundColor(AppColors.textPrimary)
                        .frame(minWidth: 30)
                }
                .onChange(of: viewModel.guestCount) { _, _ in
                    Task { @MainActor in
                        _ = viewModel.validateGuestCount()
                    }
                }
            }
            .padding(16)
            .background(AppColors.inputBackground)
            .cornerRadius(12)
            
            // Guest Error
            if let guestError = viewModel.guestError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(AppColors.error)
                    Text(guestError)
                        .appBodySmall()
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Capacity Info
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(AppColors.textTertiary)
                Text("Capacidad máxima: \(room.capacity) huéspedes")
                    .appBodySmall()
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Special Requests Section
    private var specialRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Solicitudes especiales")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            TextEditor(text: $viewModel.specialRequests)
                .frame(minHeight: 100)
                .padding(12)
                .background(AppColors.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.inputBorder, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.specialRequests.isEmpty {
                        Text("Ej: Cama extra, llegada tardía, preferencias de habitación...")
                            .appBodyMedium()
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            
            Text("Opcional - Haremos lo posible por cumplir tus solicitudes")
                .appBodySmall()
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Price Summary Section
    private var priceSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen de precio")
                    .appTitleMedium()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            Divider()
                .background(AppColors.divider)
            
            // Price per night
            HStack {
                Text("\(room.priceFormatted) × \(viewModel.numberOfNights) \(viewModel.numberOfNights == 1 ? "noche" : "noches")")
                    .appBodyMedium()
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(viewModel.totalPriceFormatted)
                    .appBodyMedium()
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
                .background(AppColors.divider)
            
            // Total
            HStack {
                Text("Total")
                    .appTitleMedium()
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(viewModel.totalPriceFormatted)
                    .appHeadlineSmall()
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    
    // MARK: - Confirm Button
    private var confirmButton: some View {
        VStack(spacing: 12) {
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.error)
                    Text(errorMessage)
                        .appBodySmall()
                        .foregroundColor(AppColors.error)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppColors.error.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button {
                Task {
                    let success = await viewModel.createReservation()
                    if success {
                        showConfirmation = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirmar Reservación")
                    }
                }
                .appLabelLarge()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isFormValid && !viewModel.isLoading ? AppColors.primary : AppColors.textTertiary)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .accessibilityLabel("Confirmar reservación")
        }
    }
}

#Preview {
    ReservationFormView(
        room: Room(
            id: UUID(),
            hotelId: UUID(),
            roomNumber: "101",
            roomType: .suite,
            price: 1500.00,
            capacity: 4,
            description: "Habitación amplia con vista al mar",
            amenities: ["WiFi", "TV", "Aire Acondicionado"],
            images: [],
            isActive: true,
            createdAt: Date()
        ),
        hotel: Hotel(
            id: UUID(),
            name: "Hotel Paradise",
            location: "Cancún, México",
            latitude: nil,
            longitude: nil,
            imageUrl: nil,
            description: nil,
            rating: 4.5,
            amenities: [],
            ownerId: UUID(),
            createdAt: Date()
        )
    )
}
