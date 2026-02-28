//
//  EditRoomView.swift
//  InnSight
//
//  Formulario para editar una habitación existente
//

import SwiftUI

struct EditRoomView: View {
    let room: Room
    let hotelId: UUID
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomNumber: String
    @State private var roomType: RoomType
    @State private var price: String
    @State private var capacity: Int
    @State private var description: String
    @State private var selectedAmenities: Set<String>
    @State private var isSaving = false
    
    private let availableAmenities = [
        "WiFi", "TV", "Aire Acondicionado", "Minibar",
        "Caja Fuerte", "Room Service", "Secadora de Pelo",
        "Plancha", "Teléfono", "Escritorio", "Balcón", "Vista al Mar"
    ]
    
    init(room: Room, hotelId: UUID, viewModel: AdminViewModel) {
        self.room = room
        self.hotelId = hotelId
        self.viewModel = viewModel
        _roomNumber = State(initialValue: room.roomNumber)
        _roomType = State(initialValue: room.roomType)
        _price = State(initialValue: "\(room.price)")
        _capacity = State(initialValue: room.capacity)
        _description = State(initialValue: room.description ?? "")
        _selectedAmenities = State(initialValue: Set(room.amenities))
    }
    
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
                        basicInfoSection
                        roomTypeSection
                        capacitySection
                        amenitiesSection
                        descriptionSection
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Editar Habitación")
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
                    let isSelected = selectedAmenities.contains(amenity)
                    let amenityInfo = Amenity.fromString(amenity)
                    
                    Button {
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
                }
            }
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
                    Text("Guardar Cambios")
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
        .accessibilityLabel(isSaving ? "Guardando cambios" : "Guardar cambios")
        .accessibilityHint(isValid ? "Toca para guardar los cambios" : "Completa los campos requeridos para guardar")
    }
    
    // MARK: - Save
    
    private func saveRoom() {
        guard let priceDecimal = Decimal(string: price) else { return }
        
        isSaving = true
        
        Task {
            let success = await viewModel.updateRoom(
                roomId: room.id,
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
