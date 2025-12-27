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
        profilePicture: Data?
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
        
        try await userRef.setData(profileData, merge: true)
    }
    
    // Fetch profile data from Firestore
    func fetchProfileFromFirestore(firebaseUID: String) async throws -> (firstName: String?, lastName: String?, phone: Int?, profilePicture: Data?, email: String?) {
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
        
        var profilePicture: Data? = nil
        if let base64String = data["profilePicture"] as? String {
            profilePicture = Data(base64Encoded: base64String)
        }
        
        return (firstName, lastName, phone, profilePicture, email)
    }
    
    // Create or update SwiftData Users object with profile information (saves to both Firestore and SwiftData)
    func createUserProfile(
        firebaseUID: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        phone: Int? = nil,
        profilePicture: Data? = nil,
        modelContext: ModelContext
    ) async throws -> Users {
        // Step 1: Save to Firestore (cloud)
        try await saveProfileToFirestore(
            firebaseUID: firebaseUID,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            profilePicture: profilePicture
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
        
        // Save to SwiftData
        return try saveProfileToSwiftData(
            firebaseUID: firebaseUID,
            email: profileData.email ?? email,
            firstName: profileData.firstName,
            lastName: profileData.lastName,
            phone: profileData.phone,
            profilePicture: profileData.profilePicture,
            modelContext: modelContext
        )
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
}
