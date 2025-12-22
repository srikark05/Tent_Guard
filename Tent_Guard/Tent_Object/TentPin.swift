import Foundation 
import SwiftData
import CoreLocation

struct TentPin: Codable, Equatable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    func distance(to other: TentPin) -> Double {
        return sqrt(pow(latitude - other.latitude, 2) + pow(longitude - other.longitude, 2))
    }
}
