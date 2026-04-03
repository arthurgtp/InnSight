//
//  AppFonts.swift
//  InnSight
//
//  Created by Arturo Gutierrez on 13/02/26.
//


//
//  AppFonts.swift
//  InnSight
//
//  Sistema de tipografía unificado para toda la aplicación
//

import SwiftUI

struct AppFonts {
    
    // MARK: - Display Styles
    static let displayLarge: Font = .system(size: 57, weight: .bold)
    static let displayMedium: Font = .system(size: 45, weight: .bold)
    static let displaySmall: Font = .system(size: 36, weight: .bold)
    
    // MARK: - Headline Styles
    static let headlineLarge: Font = .system(size: 32, weight: .semibold)
    static let headlineMedium: Font = .system(size: 28, weight: .semibold)
    static let headlineSmall: Font = .system(size: 24, weight: .semibold)
    
    // MARK: - Title Styles
    static let titleLarge: Font = .system(size: 22, weight: .medium)
    static let titleMedium: Font = .system(size: 16, weight: .medium)
    static let titleSmall: Font = .system(size: 14, weight: .medium)
    
    // MARK: - Body Styles
    static let bodyLarge: Font = .system(size: 16, weight: .regular)
    static let bodyMedium: Font = .system(size: 14, weight: .regular)
    static let bodySmall: Font = .system(size: 12, weight: .regular)
    
    // MARK: - Label Styles
    static let labelLarge: Font = .system(size: 14, weight: .medium)
    static let labelMedium: Font = .system(size: 12, weight: .medium)
    static let labelSmall: Font = .system(size: 11, weight: .medium)
    
    // MARK: - Caption Styles
    static let caption: Font = .system(size: 12, weight: .regular)
    static let overline: Font = .system(size: 10, weight: .regular)
}

// MARK: - Text Style Modifiers
extension View {
    func appDisplayLarge() -> some View {
        self.font(AppFonts.displayLarge)
    }
    
    func appDisplayMedium() -> some View {
        self.font(AppFonts.displayMedium)
    }
    
    func appDisplaySmall() -> some View {
        self.font(AppFonts.displaySmall)
    }
    
    func appHeadlineLarge() -> some View {
        self.font(AppFonts.headlineLarge)
    }
    
    func appHeadlineMedium() -> some View {
        self.font(AppFonts.headlineMedium)
    }
    
    func appHeadlineSmall() -> some View {
        self.font(AppFonts.headlineSmall)
    }
    
    func appTitleLarge() -> some View {
        self.font(AppFonts.titleLarge)
    }
    
    func appTitleMedium() -> some View {
        self.font(AppFonts.titleMedium)
    }
    
    func appTitleSmall() -> some View {
        self.font(AppFonts.titleSmall)
    }
    
    func appBodyLarge() -> some View {
        self.font(AppFonts.bodyLarge)
    }
    
    func appBodyMedium() -> some View {
        self.font(AppFonts.bodyMedium)
    }
    
    func appBodySmall() -> some View {
        self.font(AppFonts.bodySmall)
    }
    
    func appLabelLarge() -> some View {
        self.font(AppFonts.labelLarge)
    }
    
    func appLabelMedium() -> some View {
        self.font(AppFonts.labelMedium)
    }
    
    func appLabelSmall() -> some View {
        self.font(AppFonts.labelSmall)
    }
    
    func appCaption() -> some View {
        self.font(AppFonts.caption)
    }
    
    func appOverline() -> some View {
        self.font(AppFonts.overline)
    }
}