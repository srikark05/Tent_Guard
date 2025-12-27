//
//  LocationService.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/26/25.
//

import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private var updateTimer: Timer?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private var currentFirebaseUID: String?
    
    func startTrackingLocation(firebaseUID: String) {
        currentFirebaseUID = firebaseUID
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        
        // Update location to Firestore every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self, let uid = self.currentFirebaseUID else { return }
            self.updateLocationToFirestore(firebaseUID: uid)
        }
    }
    
    func stopTrackingLocation() {
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateLocationToFirestore(firebaseUID: String) {
        guard let location = currentLocation else { return }
        
        let userRef = db.collection("users").document(firebaseUID)
        userRef.updateData([
            "location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            "locationUpdatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating location to Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch all member locations from Firestore
    func fetchMemberLocations(firebaseUIDs: [String]) async throws -> [String: CLLocationCoordinate2D] {
        var locations: [String: CLLocationCoordinate2D] = [:]
        
        for firebaseUID in firebaseUIDs {
            let userRef = db.collection("users").document(firebaseUID)
            let document = try await userRef.getDocument()
            
            if let data = document.data(),
               let geoPoint = data["location"] as? GeoPoint {
                locations[firebaseUID] = CLLocationCoordinate2D(
                    latitude: geoPoint.latitude,
                    longitude: geoPoint.longitude
                )
            }
        }
        
        return locations
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Update to Firestore immediately when location is received
        if let firebaseUID = currentFirebaseUID {
            updateLocationToFirestore(firebaseUID: firebaseUID)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

