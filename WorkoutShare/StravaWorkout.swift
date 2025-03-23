import Foundation

struct StravaWorkout: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double
    let movingTime: Int?
    let type: String
    let startDate: Date
    
    var formattedDistance: String {
        let distanceInKm = distance / 1000.0
        return String(format: "%.2f km", distanceInKm)
    }
    
    var formattedDuration: String {
        guard let movingTime = movingTime else {
            return "Not available"
        }
        let hours = movingTime / 3600
        let minutes = (movingTime % 3600) / 60
        let seconds = movingTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distance
        case movingTime = "moving_time"
        case type
        case startDate = "start_date"
    }
}
