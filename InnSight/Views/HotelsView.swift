//
//  HotelsView.swift
//  InnSight
//
//  Vista principal de hoteles con diseño mejorado
//

import SwiftUI

struct HotelsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = HotelsViewModel()
    @StateObject private var locationService = LocationService()
    @StateObject private var hotelRatingService = HotelRatingService()
    @State private var showProfile = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    headerView
                    
                    // Search bar and location button
                    searchBarView
                    
                    // Location error/denied message
                    if let locationError = locationService.locationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(locationError)
                                .appBodySmall()
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    
                    // Content
                    if viewModel.hotels.isEmpty {
                        emptyStateView
                    } else if viewModel.filteredHotels.isEmpty && !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        noResultsView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredHotels, id: \.id) { hotel in
                                    HotelCard(
                                        hotel: hotel,
                                        navigationPath: $navigationPath,
                                        distance: viewModel.isSortedByProximity ? viewModel.distanceToHotel(hotel) : nil,
                                        averageRating: hotelRatingService.averageRating(for: hotel.id)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Hotel.self) { hotel in
                RoomsView(hotel: hotel, navigationPath: $navigationPath)
            }
            .navigationDestination(for: RoomNavigation.self) { roomNav in
                RoomDetailView(room: roomNav.room, hotel: roomNav.hotel, navigationPath: $navigationPath)
            }
            .task {
                await viewModel.fetchHotels()
                await hotelRatingService.fetchAverageRatings()
            }
            .refreshable {
                await viewModel.fetchHotels()
                await hotelRatingService.fetchAverageRatings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .reservationCompleted)) { _ in
                // Clear navigation path to go back to root
                navigationPath = NavigationPath()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(auth)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Logo and Title
            HStack(spacing: 10) {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("InnSight")
                        .appTitleMedium()
                        .foregroundColor(.white)
                    Text("Descubre los mejores hoteles")
                        .appBodySmall()
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Spacer()
            
            // Profile Button
            Button {
                showProfile = true
            } label: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                    )
            }
            .accessibilityLabel("Perfil")
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
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                TextField("Buscar por ciudad...", text: $viewModel.searchText)
                    .appBodyMedium()
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityLabel("Limpiar búsqueda")
                }
            }
            .padding(10)
            .background(AppColors.surface)
            .cornerRadius(10)
            
            Button {
                if viewModel.isSortedByProximity {
                    viewModel.isSortedByProximity = false
                    viewModel.userLocation = nil
                } else {
                    viewModel.isSortedByProximity = true
                    locationService.requestLocation()
                }
            } label: {
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(viewModel.isSortedByProximity ? AppColors.primary : AppColors.textSecondary)
            }
            .accessibilityLabel(viewModel.isSortedByProximity ? "Desactivar orden por cercanía" : "Ordenar por cercanía")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .onReceive(locationService.$currentLocation) { newLocation in
            if let loc = newLocation {
                viewModel.userLocation = loc
            }
        }
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text("No se encontraron hoteles para \"\(viewModel.searchText)\"")
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text("No hay hoteles disponibles")
                .appTitleLarge()
                .foregroundColor(AppColors.textPrimary)
            
            Text("Los hoteles aparecerán aquí una vez que sean agregados")
                .appBodyMedium()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Navigation Model
struct RoomNavigation: Hashable {
    let room: Room
    let hotel: Hotel
}

// MARK: - Hotel Card Component

struct HotelCard: View {
    let hotel: Hotel
    @Binding var navigationPath: NavigationPath
    var distance: Double? = nil
    var averageRating: HotelAverageRating? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hotel Image
            if let urlString = hotel.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                            ProgressView()
                        }
                        .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            }
            
            // Hotel Info
            VStack(alignment: .leading, spacing: 12) {
                // Title and Rating
                HStack(alignment: .top) {
                    Text(hotel.name)
                        .appTitleMedium()
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if let avg = averageRating, let avgValue = avg.averageRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", avgValue))
                                .appLabelMedium()
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("Sin calificación")
                            .appLabelSmall()
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                }
                
                // Location
                if let location = hotel.location {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                        Text(location)
                            .appBodySmall()
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                        
                        if let distance = distance {
                            Spacer()
                            Text(String(format: "%.1f km", distance))
                                .appLabelSmall()
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Description
                if let description = hotel.description {
                    Text(description)
                        .appBodySmall()
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                // Amenities
                let amenities = hotel.amenities
                if !amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(amenities.prefix(4), id: \.self) { amenity in
                                Text(amenity)
                                    .appLabelSmall()
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primary.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                
                // Action Button
                Button {
                    navigationPath.append(hotel)
                } label: {
                    HStack {
                        Text("Ver Habitaciones")
                            .appLabelMedium()
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
        }
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}



#Preview {
    HotelsView()
        .environmentObject(AuthViewModel())
}

