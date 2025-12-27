//
//  AuthenticationManager.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftData

struct AuthResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: FirebaseAuth.User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    
    private init() {}
    
    // Create Firebase Auth account (email/password only)
    func createUser(email: String, password: String) async throws -> AuthResultModel {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthResultModel(user: authResult.user)
    }
    
    // Save profile data to Firestore
    func saveProfileToFirestore(
        firebaseUID: String,
        email: String,
        firstName: String?,
        lastName: String?,
        phone: Int?,
        profilePicture: Data?,
        tentIDs: [String]? = nil
    ) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUID)
        
        var profileData: [String: Any] = [
            "email": email,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let firstName = firstName {
            profileData["firstName"] = firstName
        }
        
        if let lastName = lastName {
            profileData["lastName"] = lastName
        }
        
        if let phone = phone {
            profileData["phone"] = phone
        }
        
        if let profilePicture = profilePicture {
            // Convert image data to base64 string for Firestore storage
            let base64String = profilePicture.base64EncodedString()
            profileData["profilePicture"] = base64String
        }
        
        // Include tent_ids array (array of tent document IDs as strings)
        if let tentIDs = tentIDs {
            profileData["tent_ids"] = tentIDs
        } else {
            // Initialize empty array if not provided
            profileData["tent_ids"] = []
        }
        
        try await userRef.setData(profileData, merge: true)
    }
    
    // Fetch profile data from Firestore
    func fetchProfileFromFirestore(firebaseUID: String) async throws -> (firstName: String?, lastName: String?, phone: Int?, profilePicture: Data?, email: String?, tentIDs: [String]?) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUID)
        
        let document = try await userRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            throw NSError(
                domain: "AuthenticationManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile not found"]
            )
        }
        
        let firstName = data["firstName"] as? String
        let lastName = data["lastName"] as? String
        let phone = data["phone"] as? Int
        let email = data["email"] as? String
        let tentIDs = data["tent_ids"] as? [String]
        
        var profilePicture: Data? = nil
        if let base64String = data["profilePicture"] as? String {
            profilePicture = Data(base64Encoded: base64String)
        }
        
        return (firstName, lastName, phone, profilePicture, email, tentIDs)
    }
    
    // Create or update SwiftData Users object with profile information (saves to both Firestore and SwiftData)
    func createUserProfile(
        firebaseUID: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        phone: Int? = nil,
        profilePicture: Data? = nil,
        tentIDs: [String]? = nil,
        modelContext: ModelContext
    ) async throws -> Users {
        // Step 1: Save to Firestore (cloud)
        try await saveProfileToFirestore(
            firebaseUID: firebaseUID,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profilePicture: profilePicture,
            tentIDs: tentIDs
        )
        
        // Step 2: Save to SwiftData (local)
        return try saveProfileToSwiftData(
            firebaseUID: firebaseUID,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profilePicture: profilePicture,
            modelContext: modelContext
        )
    }
    
    // Save profile to SwiftData (local database)
    private func saveProfileToSwiftData(
        firebaseUID: String,
        email: String,
        firstName: String?,
        lastName: String?,
        phone: Int?,
        profilePicture: Data?,
        modelContext: ModelContext
    ) throws -> Users {
        // Check if user already exists with this Firebase UID
        let descriptor = FetchDescriptor<Users>(
            predicate: #Predicate<Users> { $0.firebaseUID == firebaseUID }
        )
        
        if let existingUser = try? modelContext.fetch(descriptor).first {
            // Update existing user
            existingUser.firstName = firstName
            existingUser.lastName = lastName
            existingUser.phone = phone
            existingUser.profilePicture = profilePicture
            existingUser.email = email
            try modelContext.save()
            return existingUser
        } else {
            // Create new user
            let user = Users(
                firebaseUID: firebaseUID,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                profilePicture: profilePicture,
                tent_id: [],
                schedule: []
            )
            modelContext.insert(user)
            try modelContext.save()
            return user
        }
    }
    
    // Sync profile from Firestore to SwiftData (used after sign-in)
    func syncProfileFromFirestore(firebaseUID: String, email: String, modelContext: ModelContext) async throws -> Users {
        // Fetch from Firestore
        let profileData = try await fetchProfileFromFirestore(firebaseUID: firebaseUID)
        
        // Convert tent_ids from Firestore (String array) to UUID array for SwiftData
        var tentUUIDs: [UUID] = []
        if let tentIDStrings = profileData.tentIDs {
            for tentIDString in tentIDStrings {
                if let uuid = UUID(uuidString: tentIDString) {
                    tentUUIDs.append(uuid)
                }
            }
        }
        
        // Save to SwiftData
        let user = try saveProfileToSwiftData(
            firebaseUID: firebaseUID,
            email: profileData.email ?? email,
            firstName: profileData.firstName,
            lastName: profileData.lastName,
            phone: profileData.phone,
            profilePicture: profileData.profilePicture,
            modelContext: modelContext
        )
        
        // Update tent_ids
        user.tent_id = tentUUIDs
        
        try modelContext.save()
        return user
    }
    
    // Sign in function
    func signIn(email: String, password: String) async throws -> AuthResultModel {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthResultModel(user: authResult.user)
    }
    
    // Sign out function
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // Get current Firebase user
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Tent Firestore Functions
    
    // Generate a random 6-digit pin
    func generateTentPin() -> Int {
        return Int.random(in: 100000...999999)
    }
    
    // Save tent to Firestore
    func saveTentToFirestore(
        tentID: UUID,
        tentName: String,
        tentPin: Int,
        tentLocation: (Double, Double),
        tentCapacity: Int,
        leaderID: UUID,
        firebaseUID: String
    ) async throws -> String {
        let db = Firestore.firestore()
        let tentRef = db.collection("tents").document(tentID.uuidString)
        
        // Create GeoPoint for geolocation
        let geoPoint = GeoPoint(latitude: tentLocation.0, longitude: tentLocation.1)
        
        let tentData: [String: Any] = [
            "tent_id": tentID.uuidString,
            "tent_name": tentName,
            "tent_pin": tentPin,
            "geolocation": geoPoint,  // Firestore GeoPoint for geospatial queries
            "tent_pin_latitude": tentLocation.0,  // Keep for backward compatibility
            "tent_pin_longitude": tentLocation.1,  // Keep for backward compatibility
            "tent_capacity": tentCapacity,
            "leader_id": [firebaseUID],  // Array of Firebase UIDs
            "group_id": [],  // Array of Firebase UIDs
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await tentRef.setData(tentData)
        return tentRef.documentID
    }
    
    // Fetch tent from Firestore by tent ID
    func fetchTentFromFirestore(tentID: String) async throws -> [String: Any]? {
        let db = Firestore.firestore()
        let tentRef = db.collection("tents").document(tentID)
        let document = try await tentRef.getDocument()
        
        guard document.exists, var data = document.data() else {
            return nil
        }
        
        // Convert GeoPoint to latitude/longitude if present
        if let geoPoint = data["geolocation"] as? GeoPoint {
            data["tent_pin_latitude"] = geoPoint.latitude
            data["tent_pin_longitude"] = geoPoint.longitude
        }
        
        // Convert boundary_coordinates from GeoPoint array to (Double, Double) tuples
        if let geoPoints = data["boundary_coordinates"] as? [GeoPoint] {
            let boundaryCoords = geoPoints.map { ($0.latitude, $0.longitude) }
            data["boundary_coordinates"] = boundaryCoords
        }
        
        return data
    }
    
    // Fetch tent from Firestore by pin
    func fetchTentByPin(tentPin: Int) async throws -> [String: Any]? {
        let db = Firestore.firestore()
        let query = db.collection("tents")
            .whereField("tent_pin", isEqualTo: tentPin)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        var data = document.data()
        
        // Convert GeoPoint to latitude/longitude if present
        if let geoPoint = data["geolocation"] as? GeoPoint {
            data["tent_pin_latitude"] = geoPoint.latitude
            data["tent_pin_longitude"] = geoPoint.longitude
        }
        
        // Convert boundary_coordinates from GeoPoint array to (Double, Double) tuples
        if let geoPoints = data["boundary_coordinates"] as? [GeoPoint] {
            let boundaryCoords = geoPoints.map { ($0.latitude, $0.longitude) }
            data["boundary_coordinates"] = boundaryCoords
        }
        
        return data
    }
    
    // Update user's tent_ids array in Firestore
    func updateUserTentIDsInFirestore(firebaseUID: String, tentIDs: [String]) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUID)
        
        try await userRef.updateData([
            "tent_ids": tentIDs,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // Add tent ID to user's tent_ids array in Firestore
    func addTentIDToUser(firebaseUID: String, tentID: String) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUID)
        
        // Get current tent_ids
        let document = try await userRef.getDocument()
        var tentIDs: [String] = []
        
        if let data = document.data(), let existingTentIDs = data["tent_ids"] as? [String] {
            tentIDs = existingTentIDs
        }
        
        // Add new tent ID if not already present
        if !tentIDs.contains(tentID) {
            tentIDs.append(tentID)
        }
        
        // Update Firestore
        try await userRef.updateData([
            "tent_ids": tentIDs,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // Add user to tent's group_id array in Firestore
    func addUserToTentGroup(tentID: String, firebaseUID: String) async throws {
        let db = Firestore.firestore()
        let tentRef = db.collection("tents").document(tentID)
        
        // Get current group_id
        let document = try await tentRef.getDocument()
        var groupIDs: [String] = []
        
        if let data = document.data(), let existingGroupIDs = data["group_id"] as? [String] {
            groupIDs = existingGroupIDs
        }
        
        // Add user if not already present
        if !groupIDs.contains(firebaseUID) {
            groupIDs.append(firebaseUID)
        }
        
        // Update Firestore
        try await tentRef.updateData([
            "group_id": groupIDs,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // Check if tent is at capacity
    func isTentAtCapacity(tentID: String) async throws -> Bool {
        let db = Firestore.firestore()
        let tentRef = db.collection("tents").document(tentID)
        let document = try await tentRef.getDocument()
        
        guard let data = document.data(),
              let capacity = data["tent_capacity"] as? Int,
              let leaderIDs = data["leader_id"] as? [String],
              let groupIDs = data["group_id"] as? [String] else {
            throw NSError(domain: "AuthenticationManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tent not found"])
        }
        
        let totalMembers = leaderIDs.count + groupIDs.count
        return totalMembers >= capacity
    }
}
