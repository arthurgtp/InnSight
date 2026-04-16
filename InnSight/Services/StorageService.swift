//
//  StorageService.swift
//  InnSight
//
//  Servicio para subir imágenes al bucket hotel-images de Supabase Storage
//

import Foundation
import Supabase
import UIKit

class StorageService {
    static let shared = StorageService()
    private init() {}

    private let bucket = "hotel-images"

    // MARK: - Upload Image → public URL

    /// Sube una UIImage al bucket y devuelve la URL pública.
    /// El bucket debe tener acceso público de lectura habilitado en Supabase.
    func uploadImage(_ image: UIImage, compressionQuality: CGFloat = 0.82) async throws -> String {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw StorageError.compressionFailed
        }
        let filename = "\(UUID().uuidString).jpg"

        try await supabase.storage
            .from(bucket)
            .upload(filename, data: data, options: FileOptions(contentType: "image/jpeg", upsert: false))

        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: filename)

        return publicURL.absoluteString
    }

    // MARK: - Upload Room Image

    /// Sube la imagen y crea el registro en room_images con los metadatos.
    func uploadRoomImage(
        _ image: UIImage,
        roomId: UUID,
        is360: Bool = false,
        isPrimary: Bool = false,
        caption: String? = nil,
        order: Int = 0
    ) async throws {
        let url = try await uploadImage(image)

        struct NewRoomImage: Encodable {
            let room_id: String
            let image_url: String
            let is_primary: Bool
            let is_360: Bool
            let caption: String?
            let display_order: Int
        }

        try await supabase
            .from("room_images")
            .insert(NewRoomImage(
                room_id: roomId.uuidString,
                image_url: url,
                is_primary: isPrimary,
                is_360: is360,
                caption: caption,
                display_order: order
            ))
            .execute()
    }

    // MARK: - Errors

    enum StorageError: LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "No se pudo comprimir la imagen seleccionada."
            }
        }
    }
}
