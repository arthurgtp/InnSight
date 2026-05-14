//
//  PricingInsightsView.swift
//  InnSight
//
//  Sección de analíticas que muestra ajustes de precio sugeridos
//  basados en el calendario mexicano + predicciones del modelo ML.
//
//  El admin puede ver qué períodos requieren ajuste de precio y aplicarlos
//  con un toque directamente desde el portal de analíticas.
//

import SwiftUI

struct PricingInsightsView: View {

    private var pricingPurple: Color { Color(hex: "8b5cf6") }

    let bundles       : [PricingBundle]
    let isLoading     : Bool
    let onApply       : (PricingBundle) async -> Void

    @State private var applyingBundleId : UUID?   = nil
    @State private var appliedIds       : Set<UUID> = []
    @State private var expandedBundle   : UUID?   = nil
    @State private var showAppliedOnly  : Bool    = false

    private var visibleBundles: [PricingBundle] {
        showAppliedOnly
            ? bundles.filter { appliedIds.contains($0.id) || $0.isApplied }
            : bundles.filter { !appliedIds.contains($0.id) && !$0.isApplied }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(AppColors.divider)

            if isLoading {
                loadingState
            } else if bundles.isEmpty {
                emptyState
            } else {
                segmentedToggle
                bundleList
            }
        }
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "tag.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(pricingPurple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Precios Dinámicos")
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text("Ajustes sugeridos por IA + calendario mexicano")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if !bundles.isEmpty {
                Text("\(bundles.filter { !$0.isApplied }.count) pendientes")
                    .font(AppFonts.labelSmall)
                    .foregroundColor(pricingPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(pricingPurple.opacity(0.12))
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Segmented toggle

    private var segmentedToggle: some View {
        HStack(spacing: 0) {
            toggleTab(label: "Por aplicar", active: !showAppliedOnly) {
                withAnimation(.easeInOut(duration: 0.2)) { showAppliedOnly = false }
            }
            toggleTab(label: "Aplicados", active: showAppliedOnly) {
                withAnimation(.easeInOut(duration: 0.2)) { showAppliedOnly = true }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func toggleTab(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.labelMedium)
                .foregroundColor(active ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(active ? AppColors.primary : Color.clear)
                .cornerRadius(8)
        }
        .padding(3)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(10)
    }

    // MARK: - Bundle List

    private var bundleList: some View {
        Group {
            if visibleBundles.isEmpty {
                Text(showAppliedOnly
                     ? "Aún no has aplicado ningún ajuste."
                     : "No hay ajustes pendientes por ahora.")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                VStack(spacing: 0) {
                    ForEach(visibleBundles) { bundle in
                        bundleCard(bundle)
                        if bundle.id != visibleBundles.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                                .background(AppColors.divider)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Bundle Card

    @ViewBuilder
    private func bundleCard(_ bundle: PricingBundle) -> some View {
        let isExpanded  = expandedBundle == bundle.id
        let isApplying  = applyingBundleId == bundle.id
        let wasApplied  = appliedIds.contains(bundle.id) || bundle.isApplied
        let pct         = bundle.averagePercentChange
        let pctLabel    = pct >= 0 ? "+\(pct)%" : "\(pct)%"
        let pctColor    = pct > 0  ? AppColors.success : (pct < 0 ? AppColors.warning : AppColors.textSecondary)
        let eventColor  = bundle.event.type.color

        VStack(spacing: 0) {
            // ── Fila principal ──────────────────────────────────────────────
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expandedBundle = isExpanded ? nil : bundle.id
                }
            } label: {
                HStack(spacing: 12) {
                    // Ícono del evento
                    Image(systemName: bundle.event.type.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(eventColor)
                        .frame(width: 36, height: 36)
                        .background(eventColor.opacity(0.12))
                        .cornerRadius(10)

                    // Info del evento
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(bundle.event.name)
                                .font(AppFonts.labelMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .lineLimit(1)
                            if bundle.event.daysUntil <= 7 && !wasApplied {
                                Text("Pronto")
                                    .font(AppFonts.overline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.error)
                                    .cornerRadius(4)
                            }
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textTertiary)
                            Text(bundle.event.dateRangeLabel)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                            Text("·")
                                .foregroundColor(AppColors.divider)
                            Text(bundle.hotelName)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // % de cambio + flecha
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(pctLabel)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(wasApplied ? AppColors.textTertiary : pctColor)

                        Text(wasApplied ? "Aplicado ✓" : "\(bundle.adjustments.count) cuartos")
                            .font(AppFonts.overline)
                            .foregroundColor(wasApplied ? AppColors.success : AppColors.textTertiary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Detalle expandible ──────────────────────────────────────────
            if isExpanded {
                VStack(spacing: 10) {
                    // Motivo
                    if !bundle.event.description.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primary)
                            Text(bundle.event.description)
                                .font(AppFonts.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    }

                    // Tabla de habitaciones
                    VStack(spacing: 0) {
                        // Header tabla
                        HStack {
                            Text("Habitación")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Precio actual")
                                .frame(width: 110, alignment: .trailing)
                            Text("Sugerido")
                                .frame(width: 100, alignment: .trailing)
                        }
                        .font(AppFonts.overline)
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                        Divider().padding(.horizontal, 16).background(AppColors.divider)

                        ForEach(bundle.adjustments) { adj in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hab. \(adj.roomNumber)")
                                        .font(AppFonts.labelSmall)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(adj.roomType.rawValue)
                                        .font(AppFonts.overline)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text(adj.basePriceFormatted)
                                    .font(AppFonts.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(width: 110, alignment: .trailing)

                                Text(adj.suggestedPriceFormatted)
                                    .font(AppFonts.labelSmall)
                                    .fontWeight(.semibold)
                                    .foregroundColor(adj.percentChange >= 0 ? AppColors.success : AppColors.warning)
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                            if adj.id != bundle.adjustments.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                                    .background(AppColors.divider)
                            }
                        }
                    }
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)

                    // Botón Aplicar
                    if !wasApplied {
                        Button {
                            Task {
                                applyingBundleId = bundle.id
                                await onApply(bundle)
                                withAnimation { appliedIds.insert(bundle.id) }
                                applyingBundleId = nil
                                expandedBundle   = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isApplying {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isApplying
                                     ? "Aplicando..."
                                     : "Aplicar \(pctLabel) a todos los cuartos")
                                    .fontWeight(.semibold)
                            }
                            .font(AppFonts.labelMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(pct >= 0 ? AppColors.primary : AppColors.warning)
                            .cornerRadius(12)
                        }
                        .disabled(isApplying)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    } else {
                        // Badge de aplicado
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Ajuste aplicado correctamente")
                        }
                        .font(AppFonts.labelSmall)
                        .foregroundColor(AppColors.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColors.success.opacity(0.10))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView().tint(AppColors.primary)
            Text("Calculando ajustes de precio...")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tag.slash")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textTertiary)
            Text("Sin ajustes en las próximas semanas")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            Text("Los precios dinámicos se activan cuando el modelo detecta días festivos, puentes o temporadas especiales.")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let cal = Calendar.current

    // Eventos de ejemplo
    let events: [CalendarEvent] = [
        CalendarEvent(name: "Semana Santa",
                      startDate: cal.date(byAdding: .day, value: 12, to: now)!,
                      endDate:   cal.date(byAdding: .day, value: 26, to: now)!,
                      type: .vacation, extraMultiplier: 1.15,
                      description: "Vacaciones de Semana Santa — alta demanda"),
        CalendarEvent(name: "Puente 1 de Mayo",
                      startDate: cal.date(byAdding: .day, value: 35, to: now)!,
                      endDate:   cal.date(byAdding: .day, value: 37, to: now)!,
                      type: .bridge,
                      description: "Puente del Día del Trabajo"),
        CalendarEvent(name: "Fin de semana",
                      startDate: cal.date(byAdding: .day, value: 5, to: now)!,
                      endDate:   cal.date(byAdding: .day, value: 6, to: now)!,
                      type: .weekend,
                      description: "Sábado y Domingo"),
    ]

    let rooms = [
        PriceAdjustment(id: UUID(), roomId: UUID(), roomNumber: "101",
                        roomType: .single, basePrice: 1500, suggestedPrice: 2100, multiplier: 1.40),
        PriceAdjustment(id: UUID(), roomId: UUID(), roomNumber: "102",
                        roomType: .deluxe, basePrice: 2500, suggestedPrice: 3500, multiplier: 1.40),
    ]

    let bundles = events.map { ev in
        PricingBundle(id: UUID(), event: ev, hotelId: UUID(),
                      hotelName: "Hotel Reforma", adjustments: rooms)
    }

    ScrollView {
        PricingInsightsView(
            bundles:   bundles,
            isLoading: false,
            onApply: { _ in }
        )
        .padding()
    }
    .background(AppColors.background)
}
