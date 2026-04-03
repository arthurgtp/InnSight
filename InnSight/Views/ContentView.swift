//
//  ContentView.swift
//  InnSight
//
//  Created by Arturo Gutierrez on 10/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        Group {
            if viewModel.isCheckingSession {
                // Mostrar loading mientras verifica sesión
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Verificando sesión...")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else if viewModel.isLoggedIn {
                
                if viewModel.role == "client" {
                    HotelsView()
                        .environmentObject(viewModel)
                } else if viewModel.role == "admin" {
                    AdminDashboardView()
                        .environmentObject(viewModel)
                } else {
                    ProgressView("Cargando perfil...")
                }
                
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}


