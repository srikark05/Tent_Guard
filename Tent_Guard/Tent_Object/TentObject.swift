import Foundation
import SwiftData

@Model
final class Tent {
    var id: UUID
    var tent_name: String
    var tent_pin_latitude: Double
    var tent_pin_longitude: Double
    var tent_capacity: Int
    var tent_users: [Users]
    
    // Computed property for tuple compatibility
    var tent_pin: (Double, Double) {
        get {
            (tent_pin_latitude, tent_pin_longitude)
        }
        set {
            tent_pin_latitude = newValue.0
            tent_pin_longitude = newValue.1
        }
    }
    
    init(id: UUID = UUID(), tent_name: String, tent_pin: (Double, Double), tent_capacity: Int, tent_users: [Users] = []) {
        self.id = id
        self.tent_name = tent_name
        self.tent_pin_latitude = tent_pin.0
        self.tent_pin_longitude = tent_pin.1
        self.tent_capacity = tent_capacity
        self.tent_users = tent_users
    }
    
    func add_user(user: Users) {
        tent_users.append(user)
    }
    
    func remove_user(user: Users) {
        tent_users.removeAll(where: { $0.user_id == user.user_id })
    }
}