//
//  RoomDetailView.swift
//  InnSight
//
//  Vista de detalle completo de una habitación
//

import SwiftUI

struct RoomDetailView: View {
    let room: Room
    let hotel: Hotel
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @State private var showReservationForm = false
    @State private var showPanorama = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Image Gallery
                    ZStack(alignment: .topLeading) {
                        ImageGalleryView(images: room.images)
                        
                        // Back Button
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.leading, 16)
                        .accessibilityLabel("Volver")
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Info
                        headerSection
                        
                        // 360° Button (if available)
                        if room.hasImage360 {
                            panoramaButton
                        }
                        
                        Divider()
                            .background(AppColors.divider)
                        
                        // Description
                        if let description = room.description, !description.isEmpty {
                            descriptionSection(description)
                            
                            Divider()
                                .background(AppColors.divider)
                        }
                        
                        // Amenities
                        if !room.amenities.isEmpty {
                            amenitiesSection
                        }
                        
                        // Bottom spacing for reserve button
                        Spacer()
                            .frame(height: 60)
                    }
                    .padding(20)
                    .background(AppColors.surface)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .offset(y: -24)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Bottom Reserve Button
            VStack {
                Spacer()
                reserveButton
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showReservationForm) {
            ReservationFormView(room: room, hotel: hotel)
        }
        .fullScreenCover(isPresented: $showPanorama) {
            if let image360 = room.image360 {
                PanoramaView(
                    imageUrl: image360.url,
                    roomName: "Habitación \(room.roomNumber)"
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Room Type Badge
            Text(room.roomType.displayName)
                .appLabelSmall()
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.primary)
                .cornerRadius(8)
            
            // Room Number
            Text("Habitación \(room.roomNumber)")
                .appHeadlineMedium()
                .foregroundColor(AppColors.textPrimary)
            
            // Hotel Name
            HStack(spacing: 6) {
                Image(systemName: "building.2")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(hotel.name)
                    .appBodyMedium()
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Price and Capacity Row
            HStack {
                // Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.priceFormatted)
                        .appHeadlineSmall()
                        .foregroundColor(AppColors.primary)
                    Text("por noche")
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Capacity
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(room.capacity)")
                            .appTitleMedium()
                            .foregroundColor(AppColors.textPrimary)
                        Text("huéspedes máx.")
                            .appBodySmall()
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surfaceSecondary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Descripción")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            Text(description)
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Panorama Button
    private var panoramaButton: some View {
        Button {
            showPanorama = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "view.3d")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vista 360°")
                        .appTitleSmall()
                        .foregroundColor(AppColors.textPrimary)
                    Text("Explora la habitación en realidad virtual")
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Amenities Section
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amenidades")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(room.amenities, id: \.self) { amenityName in
                    amenityRow(for: amenityName)
                }
            }
        }
    }
    
    // MARK: - Amenity Row
    private func amenityRow(for amenityName: String) -> some View {
        let amenity = Amenity.fromString(amenityName)
        let icon = amenity?.icon ?? "checkmark.circle"
        
        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(AppColors.primary)
                .frame(width: 24, height: 24)
            
            Text(amenityName)
                .appBodyMedium()
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(10)
    }
    
    // MARK: - Reserve Button
    private var reserveButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Precio total")
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                    Text(room.priceFormatted)
                        .appTitleLarge()
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Button {
                    showReservationForm = true
                } label: {
                    Text("Reservar")
                        .appLabelLarge()
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Reservar habitación")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppColors.surface)
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    RoomDetailView(
        room: Room(
            id: UUID(),
            hotelId: UUID(),
            roomNumber: "101",
            roomType: .suite,
            price: 1500.00,
            capacity: 2,
            description: "Habitación amplia con vista al mar, perfecta para parejas. Incluye balcón privado y jacuzzi.",
            amenities: ["WiFi", "TV", "Aire Acondicionado", "Minibar", "Caja Fuerte", "Room Service"],
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
        ),
        navigationPath: $path
    )
}
