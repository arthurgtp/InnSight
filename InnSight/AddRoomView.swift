//
//  AddRoomView.swift
//  InnSight
//
//  Formulario para agregar una nueva habitación
//

import SwiftUI

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
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Info
                        basicInfoSection
                        
                        // Room Type
                        roomTypeSection
                        
                        // Capacity
                        capacitySection
                        
                        // Amenities
                        amenitiesSection
                        
                        // Description
                        descriptionSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nueva Habitación")
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
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            // Room Number
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
            }
            
            // Price
            VStack(alignment: .leading, spacing: 8) {
                Label("Precio por Noche (MXN)", systemImage: "dollarsign.circle")
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack {
                    Text("$")
                        .font(AppFonts.titleMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("0.00", text: $price)
                        .font(AppFonts.bodyMedium)
                        .keyboardType(.decimalPad)
                }
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Room Type
    
    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tipo de Habitación", systemImage: "bed.double")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(RoomType.allCases, id: \.self) { type in
                    roomTypeButton(type)
                }
            }
        }
    }
    
    private func roomTypeButton(_ type: RoomType) -> some View {
        Button {
            roomType = type
        } label: {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                Text(type.displayName)
                    .font(AppFonts.labelMedium)
            }
            .foregroundColor(roomType == type ? .white : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(roomType == type ? AppColors.primary : AppColors.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(roomType == type ? AppColors.primary : AppColors.divider, lineWidth: 1)
            )
        }
        .accessibilityLabel(type.displayName)
        .accessibilityAddTraits(roomType == type ? .isSelected : [])
    }
    
    // MARK: - Capacity
    
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Capacidad (huéspedes)", systemImage: "person.2")
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 20) {
                Button {
                    if capacity > 1 { capacity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(capacity > 1 ? AppColors.primary : AppColors.textTertiary)
                }
                .disabled(capacity <= 1)
                .accessibilityLabel("Reducir capacidad")
                .accessibilityHint("Capacidad actual: \(capacity) huéspedes")
                
                Text("\(capacity)")
                    .font(AppFonts.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 50)
                    .accessibilityLabel("\(capacity) huéspedes")
                
                Button {
                    if capacity < 10 { capacity += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(capacity < 10 ? AppColors.primary : AppColors.textTertiary)
                }
                .disabled(capacity >= 10)
                .accessibilityLabel("Aumentar capacidad")
                .accessibilityHint("Capacidad actual: \(capacity) huéspedes")
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(availableAmenities, id: \.self) { amenity in
                    amenityToggle(amenity)
                }
            }
        }
    }
    
    private func amenityToggle(_ amenity: String) -> some View {
        let isSelected = selectedAmenities.contains(amenity)
        let amenityInfo = Amenity.fromString(amenity)
        
        return Button {
            if isSelected {
                selectedAmenities.remove(amenity)
            } else {
                selectedAmenities.insert(amenity)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: amenityInfo?.icon ?? "checkmark")
                    .font(.caption)
                Text(amenity)
                    .font(AppFonts.bodySmall)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: 1)
            )
        }
        .accessibilityLabel(amenity)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Toca para quitar" : "Toca para agregar")
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveRoom()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        .accessibilityLabel(isSaving ? "Guardando habitación" : "Guardar habitación")
        .accessibilityHint(isValid ? "Toca para guardar la habitación" : "Completa los campos requeridos para guardar")
    }
    
    // MARK: - Save
    
    private func saveRoom() {
        guard let priceDecimal = Decimal(string: price) else { return }
        
        isSaving = true
        
        Task {
            let success = await viewModel.createRoom(
                hotelId: hotelId,
                roomNumber: roomNumber.trimmingCharacters(in: .whitespaces),
                roomType: roomType,
                price: priceDecimal,
                capacity: capacity,
                description: description.isEmpty ? nil : description,
                amenities: Array(selectedAmenities)
            )
            
            isSaving = false
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    AddRoomView(hotelId: UUID(), viewModel: AdminViewModel())
}
