//
//  RoomsView.swift
//  InnSight
//
//  Vista que muestra la lista de habitaciones de un hotel
//

import SwiftUI

struct RoomsView: View {
    let hotel: Hotel
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel: RoomsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(hotel: Hotel, navigationPath: Binding<NavigationPath>) {
        self.hotel = hotel
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: RoomsViewModel(hotelId: hotel.id))
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.rooms.isEmpty {
                    emptyStateView
                } else {
                    roomsListView
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchRooms()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Volver")
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Habitaciones")
                    .appTitleMedium()
                    .foregroundColor(.white)
                Text(hotel.name)
                    .appBodySmall()
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Rooms List
    private var roomsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.rooms) { room in
                    Button {
                        navigationPath.append(RoomNavigation(room: room, hotel: hotel))
                    } label: {
                        RoomCard(room: room)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.fetchRooms()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando habitaciones...")
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bed.double")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text("No hay habitaciones disponibles")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            Text("Este hotel no tiene habitaciones registradas en este momento")
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(AppColors.error)
            
            Text("Error al cargar")
                .appTitleMedium()
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await viewModel.fetchRooms()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reintentar")
                }
                .appLabelMedium()
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        RoomsView(
            hotel: Hotel(
                id: UUID(),
                name: "Hotel Paradise",
                location: "Cancún, México",
                latitude: nil,
                longitude: nil,
                imageUrl: nil,
                description: "Un hotel de lujo",
                rating: 4.5,
                amenities: ["WiFi", "Pool"],
                ownerId: UUID(),
                createdAt: Date()
            ),
            navigationPath: $path
        )
    }
}
