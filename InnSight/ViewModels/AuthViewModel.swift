//
//  AuthViewModel.swift
//  InnSight
//
//  Created by Arturo Gutierrez on 10/02/26.
//
import Foundation
import Supabase
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var fullName: String?
    @Published var role: String?
    @Published var isCheckingSession = true
    
    init() {
        Task {
            await checkExistingSession()
        }
    }
    
    /// Verifica si existe una sesión guardada al iniciar la app
    func checkExistingSession() async {
        isCheckingSession = true
        
        do {
            let session = try await supabase.auth.session
            print("🟢 Sesión existente encontrada")
            print("User ID:", session.user.id)
            print("Email:", session.user.email ?? "sin email")
            
            isLoggedIn = true
            await fetchProfile()
        } catch {
            print("🔵 No hay sesión activa:", error.localizedDescription)
            isLoggedIn = false
        }
        
        isCheckingSession = false
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1️⃣ Intentamos hacer login
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            print("✅ Login response recibido")
            
            // 2️⃣ Verificar usuario y sesión (la respuesta es una Session)
            let session = response
            let user = session.user
            print("🟢 SESIÓN ACTIVA (usuario autenticado)")
            print("User ID:", user.id)
            print("Email:", user.email ?? "sin email")
            print("🔐 Session access token length:", session.accessToken.count)

            isLoggedIn = true
            
            // 3️⃣ Obtener el perfil (nombre completo) después de login
            await fetchProfile()
            
        } catch {
            print("❌ Error en login:", error.localizedDescription)
            errorMessage = error.localizedDescription
            isLoggedIn = false
        }
        
        // 3️⃣ Estado final de la carga
        isLoading = false
    }
    
    func fetchProfile() async {
        do {
            let session = try await supabase.auth.session
            let user = session.user

            struct Profile: Decodable {
                let full_name: String?
                let role: String?
            }

            let profile: Profile = try await supabase
                .from("profiles")
                .select("full_name, role")
                .eq("user_id", value: user.id.uuidString)
                .single()
                .execute()
                .value

            fullName = profile.full_name
            role = profile.role

            print("🟢 Perfil cargado:", fullName ?? "", role ?? "")

        } catch {
            print("❌ Error al obtener profile:", error.localizedDescription)
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        
        // 1️⃣ Crear usuario en auth
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName)
            ]
        )
        
        // En la API actual de Supabase Swift, `response.user` es no opcional
        let user = response.user
        print("✅ Usuario creado:", user.id)
    }
    
    /// Cierra la sesión actual en Supabase y limpia el estado local
    func logout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.signOut()
            
            // Limpiar estado local
            email = ""
            password = ""
            fullName = nil
            role = nil
            isLoggedIn = false
            
            print("🔒 Sesión cerrada correctamente")
        } catch {
            print("❌ Error al cerrar sesión:", error.localizedDescription)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

