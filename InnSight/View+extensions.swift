//
//  View+Extensions.swift
//  InnSight
//
//  Extensiones útiles para SwiftUI Views
//

import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    /// Notification posted when a reservation is successfully completed
    static let reservationCompleted = Notification.Name("reservationCompleted")
}

extension View {
    
    // MARK: - Card Style
    func cardStyle(backgroundColor: Color = AppColors.surface) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Primary Button Style
    func primaryButtonStyle() -> some View {
        self
            .font(AppFonts.labelLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.primaryGradient)
            .cornerRadius(12)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Secondary Button Style
    func secondaryButtonStyle() -> some View {
        self
            .font(AppFonts.labelLarge)
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.primaryLight.opacity(0.2))
            .cornerRadius(12)
    }
    
    // MARK: - Text Field Style
    func textFieldStyle(icon: String? = nil) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20)
            }
            self
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textTertiary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Badge Style
    func badgeStyle(backgroundColor: Color = AppColors.primaryLight, textColor: Color = AppColors.primary) -> some View {
        self
            .font(AppFonts.labelSmall)
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(12)
    }
    
    // MARK: - Loading Overlay
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Cargando...")
                            .foregroundColor(.white)
                            .font(AppFonts.bodyMedium)
                    }
                    .padding(32)
                    .background(AppColors.surface.opacity(0.95))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Shimmer Effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    // MARK: - Bounce Animation
    func bounceAnimation(trigger: Bool) -> some View {
        self.scaleEffect(trigger ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trigger)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
