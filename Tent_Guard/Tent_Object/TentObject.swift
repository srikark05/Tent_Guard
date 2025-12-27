import Foundation
import SwiftData

@Model
final class BoundaryCoordinate {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: (Double, Double) {
        (latitude, longitude)
    }
}

@Model
final class Tent {
    var id: UUID
    var firestoreTentID: String?  // Firestore document ID
    var tent_name: String
    var tent_pin: Int  // 6-digit random code for joining
    var tent_pin_latitude: Double  // Location latitude
    var tent_pin_longitude: Double  // Location longitude
    var tent_capacity: Int
    var leader_id: [UUID]  // Array of user IDs (creators and leaders)
    var group_id: [UUID]  // Array of user IDs (members who joined via code)
    var tent_users: [Users]  // SwiftData relationship (for local queries)
    var boundary_coordinates: [BoundaryCoordinate]  // Array of boundary coordinates for custom boundary
    
    // Computed property for location tuple compatibility
    var tent_location: (Double, Double) {
        get {
            (tent_pin_latitude, tent_pin_longitude)
        }
        set {
            tent_pin_latitude = newValue.0
            tent_pin_longitude = newValue.1
        }
    }
    
    // Computed property to get all member IDs (leaders + group members)
    var allMemberIDs: [UUID] {
        return leader_id + group_id
    }
    
    init(
        id: UUID = UUID(),
        firestoreTentID: String? = nil,
        tent_name: String,
        tent_pin: Int,
        tent_location: (Double, Double),
        tent_capacity: Int,
        leader_id: [UUID] = [],
        group_id: [UUID] = [],
        tent_users: [Users] = [],
        boundary_coordinates: [(Double, Double)] = []
    ) {
        self.id = id
        self.firestoreTentID = firestoreTentID
        self.tent_name = tent_name
        self.tent_pin = tent_pin
        self.tent_pin_latitude = tent_location.0
        self.tent_pin_longitude = tent_location.1
        self.tent_capacity = tent_capacity
        self.leader_id = leader_id
        self.group_id = group_id
        self.tent_users = tent_users
        // Convert tuples to BoundaryCoordinate objects
        self.boundary_coordinates = boundary_coordinates.map { coord in
            BoundaryCoordinate(latitude: coord.0, longitude: coord.1)
        }
    }
    
    func add_leader(userID: UUID) {
        if !leader_id.contains(userID) {
            leader_id.append(userID)
        }
    }
    
    func add_group_member(userID: UUID) {
        if !group_id.contains(userID) {
            group_id.append(userID)
        }
    }
    
    func remove_user(userID: UUID) {
        leader_id.removeAll(where: { $0 == userID })
        group_id.removeAll(where: { $0 == userID })
    }
    
    func is_leader(userID: UUID) -> Bool {
        return leader_id.contains(userID)
    }
    
    func is_member(userID: UUID) -> Bool {
        return leader_id.contains(userID) || group_id.contains(userID)
    }
}