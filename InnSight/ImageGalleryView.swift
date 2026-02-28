//
//  ImageGalleryView.swift
//  InnSight
//
//  Componente de galería de imágenes navegable para habitaciones
//

import SwiftUI

struct ImageGalleryView: View {
    let images: [RoomImage]
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if images.isEmpty {
                placeholderView
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(url: URL(string: image.url)) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                }
                            case .success(let loadedImage):
                                loadedImage
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                imagePlaceholder
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page Indicator
                if images.count > 1 {
                    pageIndicator
                }
            }
        }
        .frame(height: 280)
        .clipped()
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<images.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .padding(.bottom, 16)
    }
    
    // MARK: - Placeholder View
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("Sin imágenes disponibles")
                    .appBodyMedium()
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Image Placeholder
    private var imagePlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
    }
}

#Preview("With Images") {
    ImageGalleryView(images: [
        RoomImage(id: UUID(), roomId: UUID(), url: "https://example.com/image1.jpg", isPrimary: true, is360: false, caption: nil, order: 0),
        RoomImage(id: UUID(), roomId: UUID(), url: "https://example.com/image2.jpg", isPrimary: false, is360: false, caption: nil, order: 1)
    ])
}

#Preview("Empty") {
    ImageGalleryView(images: [])
}
