//
//  HotelRatingService.swift
//  InnSight
//
//  Servicio para consultar ratings promedio de hoteles desde la vista hotel_average_ratings
//

import Foundation
import Supabase
import Combine

@MainActor
class HotelRatingService: ObservableObject {
    @Published var ratings: [UUID: HotelAverageRating] = [:]

    func fetchAverageRatings() async {
        do {
            let results: [HotelAverageRating] = try await supabase
                .from("hotel_average_ratings")
                .select()
                .execute()
                .value

            var dict: [UUID: HotelAverageRating] = [:]
            for item in results {
                dict[item.hotelId] = item
            }
            ratings = dict
        } catch {
            print("❌ Error al obtener ratings promedio:", error.localizedDescription)
        }
    }

    func averageRating(for hotelId: UUID) -> HotelAverageRating? {
        ratings[hotelId]
    }
}
