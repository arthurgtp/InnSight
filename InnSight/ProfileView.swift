//
//  ProfileView.swift
//  InnSight
//
//  Vista de perfil de usuario
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let errorMessage = viewModel.errorMessage, viewModel.profile == nil {
                    errorView(message: errorMessage)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            profileHeader
                            statsSection
                            actionsSection
                            logoutButton
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Volver")
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchProfile()
            await viewModel.fetchReservations()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar circular con iniciales
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(viewModel.profile?.initials ?? "??")
                    .font(AppFonts.headlineLarge)
                    .foregroundColor(.white)
            }
            .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Nombre completo
            Text(viewModel.profile?.fullName ?? "Usuario")
                .font(AppFonts.titleLarge)
                .foregroundColor(AppColors.textPrimary)
            
            // Email
            if let email = viewModel.profile?.email {
                Text(email)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Badge de rol
            if let role = viewModel.profile?.role {
                roleBadge(role: role)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Role Badge
    
    private func roleBadge(role: UserRole) -> some View {
        HStack(spacing: 6) {
            Image(systemName: role.icon)
                .font(.caption)
            Text(role.displayName)
                .font(AppFonts.labelMedium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: role.color))
        .cornerRadius(20)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estadísticas")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            // Primera fila: Activas, Completadas, Canceladas
            HStack(spacing: 12) {
                NavigationLink {
                    ReservationHistoryView()
                        .environmentObject(viewModel)
                        .onAppear { viewModel.selectedFilter = .active }
                } label: {
                    statCard(
                        title: "Activas",
                        value: "\(viewModel.stats.activeReservations)",
                        icon: "clock.fill",
                        color: AppColors.success
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    ReservationHistoryView()
                        .environmentObject(viewModel)
                        .onAppear { viewModel.selectedFilter = .completed }
                } label: {
                    statCard(
                        title: "Completadas",
                        value: "\(viewModel.stats.completedReservations)",
                        icon: "checkmark.circle.fill",
                        color: AppColors.info
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    ReservationHistoryView()
                        .environmentObject(viewModel)
                        .onAppear { viewModel.selectedFilter = .cancelled }
                } label: {
                    statCard(
                        title: "Canceladas",
                        value: "\(viewModel.stats.cancelledReservations)",
                        icon: "xmark.circle.fill",
                        color: AppColors.error
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.headlineSmall)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                ReservationHistoryView()
                    .environmentObject(viewModel)
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Historial de Reservaciones")
                            .font(AppFonts.titleSmall)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Ver todas tus reservaciones")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Logout Button
    
    private var logoutButton: some View {
        Button {
            Task {
                await auth.logout()
                // Solo cerrar si el logout fue exitoso (sin error)
                if auth.errorMessage == nil {
                    await MainActor.run { dismiss() }
                } else {
                    showLogoutError = true
                }
            }
        } label: {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Cerrar Sesión")
                        .font(AppFonts.labelLarge)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.error)
            .cornerRadius(12)
        }
        .disabled(auth.isLoading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .alert("Error al cerrar sesión", isPresented: $showLogoutError) {
            Button("Aceptar", role: .cancel) {
                showLogoutError = false
            }
        } message: {
            Text(auth.errorMessage ?? "No se pudo cerrar la sesión. Intenta de nuevo.")
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(AppColors.error)
            
            Text("Error al cargar el perfil")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await viewModel.fetchProfile()
                    await viewModel.fetchReservations()
                }
            } label: {
                Text("Reintentar")
                    .font(AppFonts.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
