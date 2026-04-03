//
//  AppColors.swift
//  InnSight
//
//  Sistema de colores unificado con soporte para Dark Mode y Light Mode
//

import SwiftUI

struct AppColors {
    
    // MARK: - Primary Colors (se mantienen igual en ambos modos)
    static let primary = Color(hex: "00BCD4")
    static let primaryDark = Color(hex: "0097A7")
    static let primaryLight = Color(hex: "B2EBF2")
    
    // MARK: - Secondary Colors
    static let secondary = Color(hex: "009688")
    static let secondaryDark = Color(hex: "00796B")
    static let secondaryLight = Color(hex: "B2DFDB")
    
    // MARK: - Accent Colors
    static let accent = Color(hex: "FFC107")
    static let accentDark = Color(hex: "FFA000")
    
    // MARK: - Background Colors (Adaptativos)
    static var background: Color {
        Color(light: Color(hex: "F5F5F5"), dark: Color(hex: "121212"))
    }
    
    static var surface: Color {
        Color(light: .white, dark: Color(hex: "1E1E1E"))
    }
    
    static var surfaceSecondary: Color {
        Color(light: Color(hex: "FAFAFA"), dark: Color(hex: "2C2C2C"))
    }
    
    static var surfaceElevated: Color {
        Color(light: .white, dark: Color(hex: "2C2C2C"))
    }
    
    // MARK: - Text Colors (Adaptativos)
    static var textPrimary: Color {
        Color(light: Color(hex: "212121"), dark: Color(hex: "FFFFFF"))
    }
    
    static var textSecondary: Color {
        Color(light: Color(hex: "757575"), dark: Color(hex: "B0B0B0"))
    }
    
    static var textTertiary: Color {
        Color(light: Color(hex: "BDBDBD"), dark: Color(hex: "6B6B6B"))
    }
    
    static var textOnPrimary: Color {
        .white
    }
    
    // MARK: - Status Colors (ligeramente ajustados para dark mode)
    static var error: Color {
        Color(light: Color(hex: "F44336"), dark: Color(hex: "EF5350"))
    }
    
    static var success: Color {
        Color(light: Color(hex: "4CAF50"), dark: Color(hex: "66BB6A"))
    }
    
    static var warning: Color {
        Color(light: Color(hex: "FF9800"), dark: Color(hex: "FFA726"))
    }
    
    static var info: Color {
        Color(light: Color(hex: "2196F3"), dark: Color(hex: "42A5F5"))
    }
    
    // MARK: - Divider & Border Colors
    static var divider: Color {
        Color(light: Color(hex: "E0E0E0"), dark: Color(hex: "3D3D3D"))
    }
    
    static var border: Color {
        Color(light: Color(hex: "E0E0E0"), dark: Color(hex: "404040"))
    }
    
    // MARK: - Gradient Colors
    static let gradientStart = Color(hex: "00BCD4")
    static let gradientEnd = Color(hex: "009688")
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDark],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Card & Container Colors
    static var card: Color {
        Color(light: .white, dark: Color(hex: "252525"))
    }
    
    static var cardElevated: Color {
        Color(light: .white, dark: Color(hex: "2E2E2E"))
    }
    
    // MARK: - Input Colors
    static var inputBackground: Color {
        Color(light: Color(hex: "F5F5F5"), dark: Color(hex: "2C2C2C"))
    }
    
    static var inputBorder: Color {
        Color(light: Color(hex: "E0E0E0"), dark: Color(hex: "404040"))
    }
    
    // MARK: - Legacy support (para compatibilidad)
    static var surfaceDark: Color {
        surfaceSecondary
    }
}

// MARK: - Color Extension para Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Crea un color adaptativo que cambia según el modo de apariencia
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}
