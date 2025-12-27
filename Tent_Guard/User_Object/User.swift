import Foundation
import SwiftData

@Model
final class Users {
    var user_id: UUID
    var firebaseUID: String?  // Links to Firebase Auth
    var firstName: String?
    var lastName: String?
    var email: String 
    var phone: Int?
    var profilePicture: Data?  // Profile picture as image data
    var tent_id: [UUID]
    var schedule: [User_Schedule]
    
    // Computed property for full name
    var name: (String, String)? {
        get {
            guard let firstName = firstName, let lastName = lastName else { return nil }
            return (firstName, lastName)
        }
        set {
            if let newValue = newValue {
                firstName = newValue.0
                lastName = newValue.1
            }
        }
    }

    init(
        user_id: UUID = UUID(),
        firebaseUID: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String,
        phone: Int? = nil,
        profilePicture: Data? = nil,
        tent_id: [UUID] = [],
        schedule: [User_Schedule] = []
    ) {
        self.user_id = user_id
        self.firebaseUID = firebaseUID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.profilePicture = profilePicture
        self.tent_id = tent_id
        self.schedule = schedule
    }
    
    // Convenience initializer with tuple name
    convenience init(
        user_id: UUID = UUID(),
        firebaseUID: String? = nil,
        name: (String, String)? = nil,
        email: String,
        phone: Int? = nil,
        profilePicture: Data? = nil,
        tent_id: [UUID] = [],
        schedule: [User_Schedule] = []
    ) {
        self.init(
            user_id: user_id,
            firebaseUID: firebaseUID,
            firstName: name?.0,
            lastName: name?.1,
            email: email,
            phone: phone,
            profilePicture: profilePicture,
            tent_id: tent_id,
            schedule: schedule
        )
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
