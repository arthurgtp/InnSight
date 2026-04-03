//
//  AdminReservationFilterView.swift
//  InnSight
//
//  Panel de filtros para reservaciones del administrador
//

import SwiftUI

struct AdminReservationFilterView: View {
    @Binding var selectedStatus: ReservationStatus?
    @Binding var selectedHotel: Hotel?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let hotels: [Hotel]
    let onApply: () -> Void
    let onReset: () -> Void
    
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var useDateRange = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Filtros")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("Limpiar") {
                    onReset()
                }
                .font(AppFonts.labelMedium)
                .foregroundColor(AppColors.error)
                .accessibilityLabel("Limpiar todos los filtros")
            }
            
            // Status Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Estado")
                    .font(AppFonts.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        statusChip(nil, label: "Todos")
                        ForEach(ReservationStatus.allCases, id: \.self) { status in
                            statusChip(status, label: status.displayName)
                        }
                    }
                }
            }
            
            // Hotel Filter
            if !hotels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hotel")
                        .font(AppFonts.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Menu {
                        Button("Todos los hoteles") {
                            selectedHotel = nil
                        }
                        ForEach(hotels) { hotel in
                            Button(hotel.name) {
                                selectedHotel = hotel
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedHotel?.name ?? "Todos los hoteles")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(12)
                        .background(AppColors.inputBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.inputBorder, lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Seleccionar hotel para filtrar")
                }
            }
            
            // Date Range Filter
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $useDateRange) {
                    Text("Rango de fechas")
                        .font(AppFonts.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .tint(AppColors.primary)
                .onChange(of: useDateRange) { _, newValue in
                    if !newValue {
                        startDate = nil
                        endDate = nil
                    }
                }
                
                if useDateRange {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Desde")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                            DatePicker("", selection: $tempStartDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: tempStartDate) { _, newValue in
                                    startDate = newValue
                                }
                                .accessibilityLabel("Fecha de inicio del filtro")
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hasta")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                            DatePicker("", selection: $tempEndDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: tempEndDate) { _, newValue in
                                    endDate = newValue
                                }
                                .accessibilityLabel("Fecha de fin del filtro")
                        }
                    }
                }
            }
            
            // Apply Button
            Button {
                onApply()
            } label: {
                Text("Aplicar Filtros")
                    .primaryButtonStyle()
            }
            .accessibilityLabel("Aplicar filtros seleccionados")
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(16)
        .onAppear {
            useDateRange = startDate != nil || endDate != nil
            if let s = startDate { tempStartDate = s }
            if let e = endDate { tempEndDate = e }
        }
    }
    
    // MARK: - Status Chip
    
    private func statusChip(_ status: ReservationStatus?, label: String) -> some View {
        let isSelected = selectedStatus == status
        return Button {
            selectedStatus = status
        } label: {
            Text(label)
                .font(AppFonts.labelSmall)
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.surfaceSecondary)
                .cornerRadius(20)
        }
        .accessibilityLabel("\(label) \(isSelected ? "seleccionado" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
