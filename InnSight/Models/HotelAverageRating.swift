//
//  HotelAverageRating.swift
//  InnSight
//
//  Modelo para el rating promedio de un hotel calculado desde la vista hotel_average_ratings
//

import Foundation

struct HotelAverageRating: Codable {
    let hotelId: UUID
    let averageRating: Double?
    let ratingCount: Int

    enum CodingKeys: String, CodingKey {
        case hotelId = "hotel_id"
        case averageRating = "average_rating"
        case ratingCount = "rating_count"
    }
}
