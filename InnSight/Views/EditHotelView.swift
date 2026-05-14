//
//  EditHotelView.swift
//  InnSight
//
//  Formulario para editar un hotel existente con subida de imagen a Supabase Storage
//

import SwiftUI
import PhotosUI

struct EditHotelView: View {
    let hotel: Hotel
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var location: String
    @State private var description: String
    @State private var currentImageUrl: String   // URL ya guardada en BD

    // Image picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var newImage: UIImage?         // imagen nueva elegida (reemplaza la actual)
    @State private var isUploadingImage = false
    @State private var uploadError: String?

    @State private var isSaving = false

    init(hotel: Hotel, viewModel: AdminViewModel) {
        self.hotel = hotel
        self.viewModel = viewModel
        _name = State(initialValue: hotel.name)
        _location = State(initialValue: hotel.location ?? "")
        _description = State(initialValue: hotel.description ?? "")
        _currentImageUrl = State(initialValue: hotel.imageUrl ?? "")
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ── Imagen ────────────────────────────────────────
                        imagePicker

                        // ── Campos ────────────────────────────────────────
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
                                    Text("Guardar Cambios")
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
            .navigationTitle("Editar Hotel")
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
            // Si el admin eligió una imagen nueva, muéstrala; si no, carga la URL existente
            Group {
                if let img = newImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if !currentImageUrl.isEmpty, let url = URL(string: currentImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()

            // Spinner de subida
            if isUploadingImage {
                Color.black.opacity(0.45).frame(height: 200)
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                    Text("Cargando imagen…")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(.white)
                }
            }

            // Botón de cambiar imagen (esquina inferior derecha)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Cambiar imagen", systemImage: "pencil.circle.fill")
                            .font(AppFonts.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.primary.opacity(0.85))
                            .cornerRadius(20)
                    }
                    .padding(12)
                    .disabled(isUploadingImage)
                }
            }
            .frame(height: 200)
        }
        if let err = uploadError {
            Text(err)
                .font(AppFonts.bodySmall)
                .foregroundColor(.red)
                .padding(.horizontal, 20)
        }
    }

    private var placeholderView: some View {
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
                newImage = image
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
            // 1. Si hay imagen nueva, súbela; si no, conserva la URL actual
            var finalUrl: String? = currentImageUrl.isEmpty ? nil : currentImageUrl
            if let image = newImage {
                do {
                    finalUrl = try await StorageService.shared.uploadImage(image)
                } catch {
                    uploadError = "No se pudo subir la imagen: \(error.localizedDescription)"
                    isSaving = false
                    return
                }
            }

            // 2. Actualizar hotel
            let success = await viewModel.updateHotel(
                hotelId: hotel.id,
                name: name.trimmingCharacters(in: .whitespaces),
                location: location.isEmpty ? nil : location,
                description: description.isEmpty ? nil : description,
                imageUrl: finalUrl
            )

            isSaving = false
            if success { dismiss() }
        }
    }
}

#Preview {
    EditHotelView(
        hotel: Hotel(
            id: UUID(), name: "Hotel Paradise",
            location: "Cancún, México",
            latitude: nil, longitude: nil,
            imageUrl: nil,
            description: "Un hermoso hotel frente al mar",
            rating: 4.5, amenities: [],
            ownerId: UUID(), createdAt: Date()
        ),
        viewModel: AdminViewModel()
    )
}
