//
//  AdminHotelDetailView.swift
//  InnSight
//
//  Vista de detalle de hotel para administrador
//

import SwiftUI

struct AdminHotelDetailView: View {
    let hotel: Hotel
    @ObservedObject var viewModel: AdminViewModel
    @StateObject private var hotelRatingService = HotelRatingService()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddRoom = false
    @State private var showDeleteAlert = false
    @State private var showEditHotel = false
    @State private var roomToDelete: Room?
    @State private var roomToEdit: Room?
    @State private var showActiveReservationsWarning = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image
                    headerImage
                    
                    // Content
                    VStack(spacing: 24) {
                        // Hotel Info
                        hotelInfoSection
                        
                        Divider()
                            .background(AppColors.divider)
                        
                        // Rooms Section
                        roomsSection
                    }
                    .padding(20)
                    .background(AppColors.surface)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .offset(y: -24)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditHotel = true
                    } label: {
                        Label("Editar Hotel", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Eliminar Hotel", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.primary)
                }
                .accessibilityLabel("Opciones del hotel")
                .accessibilityHint("Toca para editar o eliminar el hotel")
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(hotelId: hotel.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showEditHotel) {
            EditHotelView(hotel: hotel, viewModel: viewModel)
        }
        .sheet(item: $roomToEdit) { room in
            EditRoomView(room: room, hotelId: hotel.id, viewModel: viewModel)
        }
        .alert("Eliminar Hotel", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteHotel()
            }
        } message: {
            Text("¿Estás seguro de eliminar \(hotel.name)? Esta acción eliminará también todas las habitaciones y no se puede deshacer.")
        }
        .alert("Eliminar Habitación", isPresented: .init(
            get: { roomToDelete != nil && !showActiveReservationsWarning },
            set: { if !$0 { roomToDelete = nil } }
        )) {
            Button("Cancelar", role: .cancel) { roomToDelete = nil }
            Button("Eliminar", role: .destructive) {
                if let room = roomToDelete {
                    deleteRoom(room)
                }
            }
        } message: {
            Text("¿Eliminar la habitación \(roomToDelete?.roomNumber ?? "")?")
        }
        .alert("No se puede eliminar", isPresented: $showActiveReservationsWarning) {
            Button("Entendido", role: .cancel) {
                roomToDelete = nil
                showActiveReservationsWarning = false
            }
        } message: {
            Text("La habitación \(roomToDelete?.roomNumber ?? "") tiene reservaciones activas. No se puede eliminar hasta que todas las reservaciones finalicen o sean canceladas.")
        }
        .task {
            await viewModel.fetchRooms(for: hotel.id)
            await hotelRatingService.fetchAverageRatings()
        }
        .onAppear {
            Task { await viewModel.fetchRooms(for: hotel.id) }
        }
    }
    
    // MARK: - Header Image
    
    private var headerImage: some View {
        AsyncImage(url: URL(string: hotel.imageUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(AppColors.surfaceSecondary)
                .overlay(
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.textTertiary)
                )
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    // MARK: - Hotel Info
    
    private var hotelInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hotel.name)
                .font(AppFonts.headlineMedium)
                .foregroundColor(AppColors.textPrimary)
            
            if let location = hotel.location {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppColors.primary)
                    Text(location)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            if let description = hotel.description, !description.isEmpty {
                Text(description)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 8)
            }
            
            // Stats Row
            HStack(spacing: 24) {
                statItem(value: "\(viewModel.rooms.count)", label: "Habitaciones", icon: "bed.double")
                if let avg = hotelRatingService.averageRating(for: hotel.id), let avgValue = avg.averageRating {
                    statItem(value: String(format: "%.1f", avgValue), label: "Rating", icon: "star.fill")
                } else {
                    statItem(value: "Sin calificación", label: "Rating", icon: "star")
                }
            }
            .padding(.top, 12)
        }
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Rooms Section
    
    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Habitaciones")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button {
                    showAddRoom = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Agregar")
                    }
                    .font(AppFonts.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
                .accessibilityLabel("Agregar nueva habitación")
            }
            
            if viewModel.rooms.isEmpty {
                emptyRoomsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.rooms) { room in
                        AdminRoomCard(
                            room: room,
                            onEdit: {
                                roomToEdit = room
                            },
                            onToggleActive: {
                                Task {
                                    await viewModel.toggleRoomActive(room, hotelId: hotel.id)
                                }
                            },
                            onDelete: {
                                roomToDelete = room
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var emptyRoomsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Sin habitaciones")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Agrega habitaciones a este hotel")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func deleteHotel() {
        Task {
            let success = await viewModel.deleteHotel(hotel)
            if success {
                dismiss()
            }
        }
    }
    
    private func deleteRoom(_ room: Room) {
        Task {
            let hasActive = await viewModel.hasActiveReservations(roomId: room.id)
            if hasActive {
                showActiveReservationsWarning = true
            } else {
                await viewModel.deleteRoom(room, hotelId: hotel.id)
                roomToDelete = nil
            }
        }
    }
}

// MARK: - Admin Room Card

struct AdminRoomCard: View {
    let room: Room
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Room Image
            if let mainImage = room.mainImage {
                AsyncImage(url: URL(string: mainImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    roomPlaceholder
                }
                .frame(width: 70, height: 70)
                .cornerRadius(10)
            } else {
                roomPlaceholder
                    .frame(width: 70, height: 70)
                    .cornerRadius(10)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hab. \(room.roomNumber)")
                        .font(AppFonts.titleSmall)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !room.isActive {
                        Text("Inactiva")
                            .font(AppFonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.error)
                            .cornerRadius(4)
                    }
                }
                
                Text(room.roomType.displayName)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(room.priceFormatted + "/noche")
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.primary)
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                
                Button {
                    onToggleActive()
                } label: {
                    Label(
                        room.isActive ? "Desactivar" : "Activar",
                        systemImage: room.isActive ? "eye.slash" : "eye"
                    )
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(12)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(12)
        .opacity(room.isActive ? 1 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Habitación \(room.roomNumber), \(room.roomType.displayName), \(room.priceFormatted) por noche\(room.isActive ? "" : ", inactiva")")
        .accessibilityHint("Toca el menú para editar, activar o eliminar")
    }
    
    private var roomPlaceholder: some View {
        Rectangle()
            .fill(AppColors.surface)
            .overlay(
                Image(systemName: "bed.double")
                    .foregroundColor(AppColors.textTertiary)
            )
    }
}

#Preview {
    NavigationStack {
        AdminHotelDetailView(
            hotel: Hotel(
                id: UUID(),
                name: "Hotel Paradise",
                location: "Cancún, México",
                latitude: nil,
                longitude: nil,
                imageUrl: nil,
                description: "Un hermoso hotel frente al mar",
                rating: 4.5,
                amenities: [],
                ownerId: UUID(),
                createdAt: Date()
            ),
            viewModel: AdminViewModel()
        )
    }
}
