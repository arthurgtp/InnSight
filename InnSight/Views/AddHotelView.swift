//
//  AddHotelView.swift
//  InnSight
//
//  Formulario para agregar un nuevo hotel con subida de imagen directa a Supabase Storage
//

import SwiftUI
import PhotosUI

struct AddHotelView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var location = ""
    @State private var description = ""

    // Image picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isUploadingImage = false
    @State private var uploadError: String?

    @State private var isSaving = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ── Imagen del hotel ──────────────────────────────
                        imagePicker

                        // ── Campos del formulario ─────────────────────────
                        VStack(spacing: 20) {
                            formField(title: "Nombre del Hotel",
                                      placeholder: "Ej: Hotel Paradise",
                                      text: $name, icon: "building.2")

                            formField(title: "Ubicación",
                                      placeholder: "Ej: Cancún, Quintana Roo",
                                      text: $location, icon: "mappin.circle")

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Descripción", systemImage: "text.alignleft")
                                    .font(AppFonts.labelMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                TextEditor(text: $description)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(AppColors.surface)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.divider, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)

                        // ── Guardar ───────────────────────────────────────
                        Button { saveHotel() } label: {
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
                            .background((isValid && !isUploadingImage) ? AppColors.primary : AppColors.textTertiary)
                            .cornerRadius(12)
                        }
                        .disabled(!isValid || isSaving || isUploadingImage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Nuevo Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(AppColors.primary)
                        .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onChange(of: selectedItem) { newItem in
                loadSelectedImage(newItem)
            }
        }
    }

    // MARK: - Image Picker

    @ViewBuilder
    private var imagePicker: some View {
        ZStack {
            // Preview or placeholder
            Group {
                if let img = previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(AppColors.surfaceSecondary)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("Toca para agregar imagen")
                                    .font(AppFonts.bodySmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        )
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()

            // Upload spinner overlay
            if isUploadingImage {
                Color.black.opacity(0.4)
                    .frame(height: 200)
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                    Text("Subiendo imagen…")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(.white)
                }
            }

            // PhotosPicker button (transparent, full area)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Color.clear.frame(height: 200).frame(maxWidth: .infinity)
            }
            .disabled(isUploadingImage)
        }
        // Error
        if let err = uploadError {
            Text(err)
                .font(AppFonts.bodySmall)
                .foregroundColor(.red)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func loadSelectedImage(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isUploadingImage = true
        uploadError = nil
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw StorageService.StorageError.compressionFailed
                }
                previewImage = image
                // upload happens on save — image is kept in memory
            } catch {
                uploadError = "Error al cargar imagen: \(error.localizedDescription)"
            }
            isUploadingImage = false
        }
    }

    private func formField(title: String, placeholder: String,
                           text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            TextField(placeholder, text: text)
                .font(AppFonts.bodyMedium)
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.divider, lineWidth: 1))
        }
    }

    // MARK: - Save

    private func saveHotel() {
        isSaving = true
        Task {
            // 1. Upload image if one was selected
            var uploadedUrl: String? = nil
            if let image = previewImage {
                do {
                    uploadedUrl = try await StorageService.shared.uploadImage(image)
                } catch {
                    uploadError = "No se pudo subir la imagen: \(error.localizedDescription)"
                    isSaving = false
                    return
                }
            }

            // 2. Create hotel
            let success = await viewModel.createHotel(
                name: name.trimmingCharacters(in: .whitespaces),
                location: location.isEmpty ? nil : location,
                description: description.isEmpty ? nil : description,
                imageUrl: uploadedUrl
            )

            isSaving = false
            if success { dismiss() }
        }
    }
}

#Preview {
    AddHotelView(viewModel: AdminViewModel())
}
