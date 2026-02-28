//
//  LoginView.swift
//  InnSight
//
//  Vista de inicio de sesión con diseño mejorado
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showRegister = false
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("InnSight")
                            .appDisplaySmall()
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text("Tu sistema inteligente de gestión hotelera")
                            .appBodyMedium()
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo Electrónico")
                                .appLabelMedium()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("ejemplo@correo.com", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .foregroundColor(AppColors.textPrimary)
                                    .tint(AppColors.primary)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .environment(\.colorScheme, .light)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contraseña")
                                .appLabelMedium()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                if showPassword {
                                    TextField("Contraseña", text: $viewModel.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            Task { await viewModel.login() }
                                        }
                                } else {
                                    SecureField("Contraseña", text: $viewModel.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            Task { await viewModel.login() }
                                        }
                                }
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .environment(\.colorScheme, .light)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .appBodySmall()
                            }
                            .foregroundColor(AppColors.error)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Login Button
                        Button {
                            focusedField = nil
                            Task {
                                await viewModel.login()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Iniciar Sesión")
                                        .appLabelLarge()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(AppColors.primary)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                        .opacity((viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty) ? 0.6 : 1.0)
                        
                        // Register Link
                        Button {
                            showRegister = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("¿No tienes cuenta?")
                                    .foregroundColor(.cyan.opacity(0.8))
                                Text("Regístrate")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.cyan)
                            }
                            .appBodyMedium()
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(AppColors.surface.opacity(0.95))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
