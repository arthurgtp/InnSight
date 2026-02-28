//
//  CommentService.swift
//  InnSight
//
//  Servicio para gestionar comentarios de reservaciones
//

import Foundation
import Supabase
import Combine

@MainActor
class CommentService: ObservableObject {
    @Published var comment: Comment?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Fetches the current client's comment for a reservation
    func fetchComment(for reservationId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id

            let comments: [Comment] = try await supabase
                .from("reservation_comments")
                .select()
                .eq("reservation_id", value: reservationId.uuidString)
                .eq("client_id", value: userId.uuidString)
                .execute()
                .value

            comment = comments.first
        } catch {
            print("❌ Error al obtener comentario:", error.localizedDescription)
            errorMessage = "No se pudo cargar el comentario."
        }

        isLoading = false
    }

    /// Fetches a comment for a reservation as admin (no client_id filter)
    func fetchCommentAsAdmin(for reservationId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let comments: [Comment] = try await supabase
                .from("reservation_comments")
                .select()
                .eq("reservation_id", value: reservationId.uuidString)
                .execute()
                .value

            comment = comments.first
        } catch {
            print("❌ Error al obtener comentario (admin):", error.localizedDescription)
            errorMessage = "No se pudo cargar el comentario."
        }

        isLoading = false
    }

    /// Submits a comment with rating for a reservation. Returns true on success.
    func submitComment(reservationId: UUID, text: String, rating: Int) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "El comentario no puede estar vacío."
            return false
        }

        guard rating >= 1 && rating <= 5 else {
            errorMessage = "Selecciona una evaluación del 1 al 5"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id

            let newComment: Comment = try await supabase
                .from("reservation_comments")
                .insert([
                    "reservation_id": reservationId.uuidString,
                    "client_id": userId.uuidString,
                    "comment_text": trimmed,
                    "rating": "\(rating)"
                ])
                .select()
                .single()
                .execute()
                .value

            comment = newComment
            isLoading = false
            return true
        } catch {
            let errorString = error.localizedDescription
            if errorString.contains("duplicate") || errorString.contains("unique") || errorString.contains("23505") {
                errorMessage = "Ya has dejado un comentario para esta reservación."
            } else {
                print("❌ Error al enviar comentario:", errorString)
                errorMessage = "No se pudo enviar el comentario. Intenta de nuevo."
            }
            isLoading = false
            return false
        }
    }
}
