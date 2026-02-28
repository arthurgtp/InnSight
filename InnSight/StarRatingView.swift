//
//  StarRatingView.swift
//  InnSight
//
//  Componente reutilizable para selección y visualización de estrellas
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5
    let isInteractive: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(AppColors.accent)
                    .font(AppFonts.titleMedium)
                    .onTapGesture {
                        if isInteractive {
                            rating = index
                        }
                    }
                    .accessibilityLabel("\(index) estrella\(index == 1 ? "" : "s")")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evaluación: \(rating) de \(maxRating) estrellas")
    }
}
