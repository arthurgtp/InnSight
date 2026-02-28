import Foundation

/// Calculates the great-circle distance between two points on Earth
/// using the Haversine formula.
/// - Parameters:
///   - lat1: Latitude of the first point in degrees
///   - lon1: Longitude of the first point in degrees
///   - lat2: Latitude of the second point in degrees
///   - lon2: Longitude of the second point in degrees
/// - Returns: Distance in kilometers
func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
    let earthRadius = 6371.0 // km

    let dLat = (lat2 - lat1) * .pi / 180.0
    let dLon = (lon2 - lon1) * .pi / 180.0

    let lat1Rad = lat1 * .pi / 180.0
    let lat2Rad = lat2 * .pi / 180.0

    let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1Rad) * cos(lat2Rad) *
            sin(dLon / 2) * sin(dLon / 2)

    let c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return earthRadius * c
}
