//
//  AddRoomView.swift
//  InnSight
//
//  Formulario para agregar una nueva habitación con subida de imágenes a Supabase Storage
//

import SwiftUI
import PhotosUI

struct AddRoomView: View {
    let hotelId: UUID
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var roomNumber = ""
    @State private var roomType: RoomType = .double
    @State private var price = ""
    @State private var capacity = 2
    @State private var description = ""
    @State private var selectedAmenities: Set<String> = []

    // Images
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var roomImages: [RoomImageDraft] = []   // imágenes listas para subir
    @State private var uploadError: String?

    @State private var isSaving = false

    private let availableAmenities = [
        "WiFi", "TV", "Aire Acondicionado", "Minibar",
        "Caja Fuerte", "Room Service", "Secadora de Pelo",
        "Plancha", "Teléfono", "Escritorio", "Balcón", "Vista al Mar"
    ]

    var isValid: Bool {
        !roomNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.isEmpty &&
        (Decimal(string: price) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        basicInfoSection
                        roomTypeSection
                        capacitySection
                        imagesSection       // ← nuevo
                        amenitiesSection
                        descriptionSection
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nueva Habitación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(AppColors.primary)
                        .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onChange(of: selectedItems) { items in
                loadNewImages(items)
            }
        }
    }

    // MARK: - Images Section

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Imágenes de la Habitación", systemImage: "photo.on.rectangle.angled")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)

            // Grid de miniaturas
            if !roomImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach($roomImages) { $draft in
                        ImageDraftCard(draft: $draft) {
                            roomImages.removeAll { $0.id == draft.id }
                        }
                    }
                }
            }

            if let err = uploadError {
                Text(err)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(.red)
            }

            // Botón agregar más imágenes
            PhotosPicker(selection: $selectedItems,
                         maxSelectionCount: 10,
                         matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(roomImages.isEmpty ? "Agregar imágenes" : "Agregar más")
                }
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primary.opacity(0.4), lineWidth: 1))
            }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Número de Habitación", systemImage: "number")
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                TextField("Ej: 101", text: $roomNumber)
                    .font(AppFonts.bodyMedium)
                    .keyboardType(.numberPad)
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Precio por Noche (MXN)", systemImage: "dollarsign.circle")
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                HStack {
                    Text("$").font(AppFonts.titleMedium).foregroundColor(AppColors.textSecondary)
                    TextField("0.00", text: $price)
                        .font(AppFonts.bodyMedium)
                        .keyboardType(.decimalPad)
                }
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.divider, lineWidth: 1))
            }
        }
    }

    // MARK: - Room Type

    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tipo de Habitación", systemImage: "bed.double")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(RoomType.allCases, id: \.self) { type in
                    Button { roomType = type } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                            Text(type.displayName).font(AppFonts.labelMedium)
                        }
                        .foregroundColor(roomType == type ? .white : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(roomType == type ? AppColors.primary : AppColors.surface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(roomType == type ? AppColors.primary : AppColors.divider, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Capacity

    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Capacidad (huéspedes)", systemImage: "person.2")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 20) {
                Button { if capacity > 1 { capacity -= 1 } } label: {
                    Image(systemName: "minus.circle.fill").font(.title)
                        .foregroundColor(capacity > 1 ? AppColors.primary : AppColors.textTertiary)
                }
                .disabled(capacity <= 1)
                Text("\(capacity)").font(AppFonts.headlineMedium)
                    .foregroundColor(AppColors.textPrimary).frame(width: 50)
                Button { if capacity < 10 { capacity += 1 } } label: {
                    Image(systemName: "plus.circle.fill").font(.title)
                        .foregroundColor(capacity < 10 ? AppColors.primary : AppColors.textTertiary)
                }
                .disabled(capacity >= 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Amenities

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Amenidades", systemImage: "checkmark.circle")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(availableAmenities, id: \.self) { amenity in
                    amenityToggle(amenity)
                }
            }
        }
    }

    private func amenityToggle(_ amenity: String) -> some View {
        let isSelected = selectedAmenities.contains(amenity)
        let icon = Amenity.fromString(amenity)?.icon ?? "checkmark"
        return Button {
            if isSelected { selectedAmenities.remove(amenity) }
            else { selectedAmenities.insert(amenity) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(amenity).font(AppFonts.bodySmall).lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10).padding(.horizontal, 8)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: 1))
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Descripción (opcional)", systemImage: "text.alignleft")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            TextEditor(text: $description)
                .frame(minHeight: 80)
                .padding(12)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.divider, lineWidth: 1))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button { saveRoom() } label: {
            HStack {
                if isSaving {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Guardando…")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Guardar Habitación")
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
    }

    // MARK: - Load images from picker

    private func loadNewImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        uploadError = nil
        Task {
            var newDrafts: [RoomImageDraft] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newDrafts.append(RoomImageDraft(image: image))
                }
            }
            // Primera imagen de la primera tanda es la principal por defecto
            if roomImages.isEmpty, var first = newDrafts.first {
                first.isPrimary = true
                newDrafts[0] = first
            }
            roomImages.append(contentsOf: newDrafts)
            selectedItems = []  // reset picker
        }
    }

    // MARK: - Save

    private func saveRoom() {
        guard let priceDecimal = Decimal(string: price) else { return }
        isSaving = true
        uploadError = nil

        Task {
            // 1. Crear habitación y obtener su UUID
            guard let roomId = await viewModel.createRoom(
                hotelId: hotelId,
                roomNumber: roomNumber.trimmingCharacters(in: .whitespaces),
                roomType: roomType,
                price: priceDecimal,
                capacity: capacity,
                description: description.isEmpty ? nil : description,
                amenities: Array(selectedAmenities)
            ) else {
                isSaving = false
                return
            }

            // 2. Subir imágenes una por una
            for (index, draft) in roomImages.enumerated() {
                do {
                    try await StorageService.shared.uploadRoomImage(
                        draft.image,
                        roomId: roomId,
                        is360: draft.is360,
                        isPrimary: draft.isPrimary,
                        caption: draft.is360 ? "Vista 360°" : nil,
                        order: index
                    )
                } catch {
                    uploadError = "Error al subir imagen \(index + 1): \(error.localizedDescription)"
                    // Continúa con las demás imágenes aunque una falle
                }
            }

            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Room Image Draft (imagen local antes de subir)

struct RoomImageDraft: Identifiable {
    let id = UUID()
    let image: UIImage
    var isPrimary: Bool = false
    var is360: Bool = false
}

// MARK: - Image Draft Card

struct ImageDraftCard: View {
    @Binding var draft: RoomImageDraft
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Image(uiImage: draft.image)
                .resizable()
                .scaledToFill()
                .frame(height: 90)
                .clipped()
                .cornerRadius(10)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
        // Toggles
        VStack(spacing: 4) {
            Toggle(isOn: $draft.isPrimary) {
                Text("Principal").font(.system(size: 11))
            }
            .toggleStyle(.button)
            .tint(AppColors.primary)

            Toggle(isOn: $draft.is360) {
                Text("360°").font(.system(size: 11))
            }
            .toggleStyle(.button)
            .tint(.purple)
        }
        .padding(.top, 4)
    }
}

#Preview {
    AddRoomView(hotelId: UUID(), viewModel: AdminViewModel())
}
