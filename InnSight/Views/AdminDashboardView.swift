//
//  AdminDashboardView.swift
//  InnSight
//
//  Panel principal de administración con navegación por pestañas
//

import SwiftUI
import Supabase

// MARK: - Dashboard Tab Enum

enum DashboardTab: String, CaseIterable {
    case overview = "Resumen"
    case hotels = "Hoteles"
    case reservations = "Reservaciones"
    case analytics = "Analíticas"
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .hotels: return "building.2.fill"
        case .reservations: return "calendar.badge.clock"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Admin Dashboard View

struct AdminDashboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = AdminViewModel()
    @StateObject private var statisticsVM = StatisticsViewModel()
    @StateObject private var notificationsVM = NotificationsViewModel()
    @StateObject private var hotelRatingService = HotelRatingService()
    
    @State private var selectedTab: DashboardTab = .overview
    @State private var showAddHotel = false
    @State private var showAddRoom = false
    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var selectedHotelForRoom: Hotel?
    @State private var hasLoadedInitialData = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Tab Content
                    tabContent
                    
                    // Custom Tab Bar
                    customTabBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddHotel) {
                AddHotelView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddRoom) {
                if let hotel = selectedHotelForRoom {
                    AddRoomView(hotelId: hotel.id, viewModel: viewModel)
                } else {
                    hotelSelectionForRoom
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(auth)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView(hotels: viewModel.hotels)
            }
        }
        .task {
            guard !hasLoadedInitialData else { return }
            hasLoadedInitialData = true
            await loadData()
        }
        .onChange(of: selectedTab) {
            Task { await refreshCurrentTab() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await loadData() }
        }
    }
    
    // MARK: - Refresh Current Tab
    
    private func refreshCurrentTab() async {
        switch selectedTab {
        case .overview:
            do {
                let session = try await supabase.auth.session
                await statisticsVM.fetchStatistics(for: session.user.id)
                await notificationsVM.fetchNotifications(for: session.user.id)
            } catch {
                print("❌ Error refreshing overview: \(error)")
            }
        case .hotels:
            await viewModel.fetchHotels()
        case .reservations, .analytics:
            // These views manage their own data loading via .task
            break
        }
    }
    
    // MARK: - Load Data
    
    private func loadData() async {
        // Prevent concurrent refresh calls
        guard !isRefreshing else { return }
        isRefreshing = true
        
        defer { isRefreshing = false }
        
        // Fetch hotels first
        await viewModel.fetchHotels()
        await hotelRatingService.fetchAverageRatings()
        
        // Then fetch statistics and notifications
        do {
            let session = try await supabase.auth.session
            await statisticsVM.fetchStatistics(for: session.user.id)
            await notificationsVM.fetchNotifications(for: session.user.id)
        } catch {
            print("❌ Error getting session for statistics: \(error)")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Panel de Admin")
                    .font(AppFonts.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text(headerSubtitle)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Notifications bell
            Button {
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.textSecondary)
                    
                    if notificationsVM.unreadCount > 0 {
                        Text(notificationsVM.unreadCount > 99 ? "99+" : "\(notificationsVM.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppColors.error)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            }
            .accessibilityLabel("Notificaciones, \(notificationsVM.unreadCount) sin leer")
            .padding(.trailing, 8)
            
            Button {
                showProfile = true
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.primary)
            }
            .accessibilityLabel("Ver perfil")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }
    
    private var headerSubtitle: String {
        switch selectedTab {
        case .overview:
            return "Resumen de tu negocio"
        case .hotels:
            return "Gestiona tus hoteles"
        case .reservations:
            return "Administra reservaciones"
        case .analytics:
            return "Analiza tu rendimiento"
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            overviewTab
                .tag(DashboardTab.overview)
            
            hotelsTab
                .tag(DashboardTab.hotels)
            
            reservationsTab
                .tag(DashboardTab.reservations)
            
            analyticsTab
                .tag(DashboardTab.analytics)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Statistics Section
                OverviewSection(statisticsVM: statisticsVM, onQuickAction: { action in
                    handleQuickAction(action)
                }, onRetry: {
                    Task { await loadData() }
                })
                .padding(.horizontal, 20)
                
                // Quick Actions Section
                QuickActionsView(actions: QuickAction.defaultActions) { action in
                    handleQuickAction(action.type)
                }
                .padding(.horizontal, 20)
                
                // Recent Hotels Preview
                if !viewModel.hotels.isEmpty {
                    recentHotelsSection
                }
            }
            .padding(.vertical, 20)
        }
        .refreshable {
            await loadData()
        }
    }
    
    private var recentHotelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hoteles Recientes")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button {
                    selectedTab = .hotels
                } label: {
                    Text("Ver todos")
                        .font(AppFonts.labelMedium)
                        .foregroundColor(AppColors.primary)
                }
                .accessibilityLabel("Ver todos los hoteles")
            }
            
            // Show first 3 hotels
            ForEach(viewModel.hotels.prefix(3)) { hotel in
                NavigationLink {
                    AdminHotelDetailView(hotel: hotel, viewModel: viewModel)
                } label: {
                    AdminHotelCard(hotel: hotel, averageRating: hotelRatingService.averageRating(for: hotel.id))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Hotels Tab
    
    private var hotelsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add Hotel Button
                HStack {
                    Spacer()
                    
                    Button {
                        showAddHotel = true
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
                    .accessibilityLabel("Agregar nuevo hotel")
                }
                .padding(.horizontal, 20)
                
                if viewModel.isLoading && viewModel.hotels.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.hotels.isEmpty {
                    errorView(error)
                } else if viewModel.hotels.isEmpty {
                    emptyHotelsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.hotels) { hotel in
                            NavigationLink {
                                AdminHotelDetailView(hotel: hotel, viewModel: viewModel)
                            } label: {
                                AdminHotelCard(hotel: hotel, averageRating: hotelRatingService.averageRating(for: hotel.id))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .refreshable {
            await viewModel.fetchHotels()
            await hotelRatingService.fetchAverageRatings()
        }
    }
    
    // MARK: - Reservations Tab
    
    private var reservationsTab: some View {
        AdminReservationsView(hotels: viewModel.hotels)
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTab: some View {
        AnalyticsView(hotels: viewModel.hotels)
    }

    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                tabBarItem(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(AppColors.surface)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
    }
    
    private func tabBarItem(for tab: DashboardTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                
                Text(tab.rawValue)
                    .font(AppFonts.caption)
            }
            .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
    
    // MARK: - Quick Action Handler
    
    private func handleQuickAction(_ action: QuickActionType) {
        switch action {
        case .addHotel:
            showAddHotel = true
        case .addRoom:
            if viewModel.hotels.isEmpty {
                // Show add hotel first if no hotels exist
                showAddHotel = true
            } else if viewModel.hotels.count == 1 {
                // If only one hotel, go directly to add room
                selectedHotelForRoom = viewModel.hotels.first
                showAddRoom = true
            } else {
                // Show hotel selection
                selectedHotelForRoom = nil
                showAddRoom = true
            }
        case .viewReservations:
            selectedTab = .reservations
        case .viewAnalytics:
            selectedTab = .analytics
        }
    }
    
    // MARK: - Hotel Selection for Room
    
    private var hotelSelectionForRoom: some View {
        NavigationStack {
            List(viewModel.hotels) { hotel in
                Button {
                    selectedHotelForRoom = hotel
                } label: {
                    HStack {
                        AsyncImage(url: URL(string: hotel.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(AppColors.surfaceSecondary)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .foregroundColor(AppColors.textTertiary)
                                )
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hotel.name)
                                .font(AppFonts.titleSmall)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if let location = hotel.location {
                                Text(location)
                                    .font(AppFonts.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .navigationTitle("Seleccionar Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showAddRoom = false
                    }
                }
            }
            .sheet(item: $selectedHotelForRoom) { hotel in
                AddRoomView(hotelId: hotel.id, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando...")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
                Task { await viewModel.fetchHotels() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .accessibilityLabel("Reintentar carga de hoteles")
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyHotelsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No tienes hoteles")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Agrega tu primer hotel para comenzar")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Button {
                showAddHotel = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Agregar Hotel")
                }
                .font(AppFonts.labelLarge)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            .accessibilityLabel("Agregar primer hotel")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

// MARK: - Admin Hotel Card

struct AdminHotelCard: View {
    let hotel: Hotel
    var averageRating: HotelAverageRating? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            AsyncImage(url: URL(string: hotel.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppColors.surfaceSecondary)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.title)
                            .foregroundColor(AppColors.textTertiary)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(hotel.name)
                    .font(AppFonts.titleSmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                if let location = hotel.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                }
                
                if let avg = averageRating, let avgValue = avg.averageRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", avgValue))
                            .font(AppFonts.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    Text("Sin calificación")
                        .font(AppFonts.labelSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hotel.name), \(hotel.location ?? "Sin ubicación")")
    }
}

// MARK: - Preview

#Preview {
    AdminDashboardView()
        .environmentObject(AuthViewModel())
}
