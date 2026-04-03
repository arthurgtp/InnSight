//
//  Comment.swift
//  InnSight
//
//  Modelo de comentario para reservaciones
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: UUID
    let reservationId: UUID
    let clientId: UUID
    let commentText: String
    let rating: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "comment_id"
        case reservationId = "reservation_id"
        case clientId = "client_id"
        case commentText = "comment_text"
        case rating
        case createdAt = "created_at"
    }
}
