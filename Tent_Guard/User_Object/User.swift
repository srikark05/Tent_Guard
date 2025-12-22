import Foundation
import SwiftData

@Model
final class Users {
    var user_id: UUID
    var firstName: String
    var lastName: String
    var email: String 
    var phone: Int
    var tent_id: [UUID]
    var schedule: [User_Schedule]
    
    // Computed property for full name
    var name: (String, String) {
        get {
            (firstName, lastName)
        }
        set {
            firstName = newValue.0
            lastName = newValue.1
        }
    }

    init(user_id: UUID = UUID(), firstName: String, lastName: String, email: String, phone: Int, tent_id: [UUID] = [], schedule: [User_Schedule] = []) {
        self.user_id = user_id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.tent_id = tent_id
        self.schedule = schedule
    }
    
    // Convenience initializer with tuple name
    convenience init(user_id: UUID = UUID(), name: (String, String), email: String, phone: Int, tent_id: [UUID] = [], schedule: [User_Schedule] = []) {
        self.init(user_id: user_id, firstName: name.0, lastName: name.1, email: email, phone: phone, tent_id: tent_id, schedule: schedule)
    }

    func join_tent(tent: Tent) {
        if !tent_id.contains(tent.id) {
            tent_id.append(tent.id)
        }
    }
    
    func leave_tent(tent: Tent) {
        tent_id.removeAll(where: { $0 == tent.id })
    }
}
