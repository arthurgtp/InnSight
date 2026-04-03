//
//  RegisterView.swift
//  InnSight
//
//  Vista de registro con diseño mejorado
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum Field {
        case fullName, email, password, confirmPassword
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
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Volver")
                                }
                                .foregroundColor(.white)
                                .appBodyMedium()
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("Crear Cuenta")
                            .appDisplaySmall()
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text("Únete a InnSight y comienza a gestionar")
                            .appBodyMedium()
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Register Form
                    VStack(spacing: 20) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre Completo")
                                .appLabelMedium()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("Juan Pérez", text: $fullName)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .foregroundColor(AppColors.textPrimary)
                                    .tint(AppColors.primary)
                                    .onSubmit {
                                        focusedField = .email
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .environment(\.colorScheme, .light)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo Electrónico")
                                .appLabelMedium()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("ejemplo@correo.com", text: $email)
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
                                    TextField("Mínimo 6 caracteres", text: $password)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            focusedField = .confirmPassword
                                        }
                                } else {
                                    SecureField("Mínimo 6 caracteres", text: $password)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            focusedField = .confirmPassword
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
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmar Contraseña")
                                .appLabelMedium()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                if showConfirmPassword {
                                    TextField("Repite tu contraseña", text: $confirmPassword)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            registerUser()
                                        }
                                } else {
                                    SecureField("Repite tu contraseña", text: $confirmPassword)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .foregroundColor(AppColors.textPrimary)
                                        .tint(AppColors.primary)
                                        .onSubmit {
                                            registerUser()
                                        }
                                }
                                
                                Button {
                                    showConfirmPassword.toggle()
                                } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                        if let error = errorMessage {
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
                        
                        // Register Button
                        Button {
                            focusedField = nil
                            registerUser()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Crear Cuenta")
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
                        .disabled(isLoading || !isFormValid)
                        .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                        
                        // Terms and conditions
                        Text("Al registrarte, aceptas nuestros Términos y Condiciones")
                            .appBodySmall()
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
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
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    // MARK: - Methods
    
    private func registerUser() {
        guard isFormValid else {
            if password != confirmPassword {
                errorMessage = "Las contraseñas no coinciden"
            } else if password.count < 6 {
                errorMessage = "La contraseña debe tener al menos 6 caracteres"
            } else {
                errorMessage = "Por favor completa todos los campos"
            }
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                try await viewModel.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )
                
                print("🎉 Registro completo")
                dismiss()
                
            } catch {
                print("❌ Error en registro:", error.localizedDescription)
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}

