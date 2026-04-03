//
//  AddHotelView.swift
//  InnSight
//
//  Formulario para agregar un nuevo hotel
//

import SwiftUI

struct AddHotelView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var location = ""
    @State private var description = ""
    @State private var imageUrl = ""
    @State private var isSaving = false
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Preview
                        imagePreview
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            formField(
                                title: "Nombre del Hotel",
                                placeholder: "Ej: Hotel Paradise",
                                text: $name,
                                icon: "building.2"
                            )
                            
                            formField(
                                title: "Ubicación",
                                placeholder: "Ej: Cancún, Quintana Roo",
                                text: $location,
                                icon: "mappin.circle"
                            )
                            
                            formField(
                                title: "URL de Imagen",
                                placeholder: "https://...",
                                text: $imageUrl,
                                icon: "photo"
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Descripción", systemImage: "text.alignleft")
                                    .font(AppFonts.labelMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextEditor(text: $description)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(AppColors.surface)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.divider, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button {
                            saveHotel()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Guardar Hotel")
                                }
                            }
                            .font(AppFonts.labelLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isValid ? AppColors.primary : AppColors.textTertiary)
                            .cornerRadius(12)
                        }
                        .disabled(!isValid || isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .accessibilityLabel(isSaving ? "Guardando hotel" : "Guardar hotel")
                        .accessibilityHint(isValid ? "Toca para guardar el nuevo hotel" : "El nombre del hotel es requerido")
                    }
                }
            }
            .navigationTitle("Nuevo Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private var imagePreview: some View {
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderImage
            case .empty:
                if imageUrl.isEmpty {
                    placeholderImage
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(AppColors.surfaceSecondary)
                }
            @unknown default:
                placeholderImage
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(AppColors.surfaceSecondary)
            .frame(height: 200)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    Text("Agrega una URL de imagen")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            )
    }
    
    // MARK: - Form Field
    
    private func formField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: text)
                .font(AppFonts.bodyMedium)
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Save
    
    private func saveHotel() {
        isSaving = true
        
        Task {
            let success = await viewModel.createHotel(
                name: name.trimmingCharacters(in: .whitespaces),
                location: location.isEmpty ? nil : location,
                description: description.isEmpty ? nil : description,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl
            )
            
            isSaving = false
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    AddHotelView(viewModel: AdminViewModel())
}
