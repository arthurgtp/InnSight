//
//  RoomCard.swift
//  InnSight
//
//  Componente de tarjeta para mostrar una habitación en la lista
//

import SwiftUI

struct RoomCard: View {
    let room: Room
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Room Image
            ZStack(alignment: .topTrailing) {
                if let mainImage = room.mainImage, let url = URL(string: mainImage.url) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                ProgressView()
                            }
                            .frame(height: 160)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipped()
                        case .failure:
                            placeholderImage
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Room Type Badge
                Text(room.roomType.displayName)
                    .appLabelSmall()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                    .padding(12)
            }
            
            // Room Info
            VStack(alignment: .leading, spacing: 10) {
                // Room Number
                Text("Habitación \(room.roomNumber)")
                    .appTitleMedium()
                    .foregroundColor(AppColors.textPrimary)
                
                // Price and Capacity Row
                HStack {
                    // Price
                    Text(room.priceFormatted)
                        .appTitleLarge()
                        .foregroundColor(AppColors.primary)
                    
                    Text("/ noche")
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    // Capacity
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(room.capacity)")
                            .appLabelMedium()
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(8)
                }
            }
            .padding(16)
        }
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Placeholder Image
    private var placeholderImage: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            Image(systemName: "bed.double")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
        .frame(height: 160)
    }
}

#Preview {
    RoomCard(room: Room(
        id: UUID(),
        hotelId: UUID(),
        roomNumber: "101",
        roomType: .suite,
        price: 1500.00,
        capacity: 2,
        description: "Habitación con vista al mar",
        amenities: ["WiFi", "TV", "Aire Acondicionado"],
        images: [],
        isActive: true,
        createdAt: Date()
    ))
    .padding()
}
