//
//  TentGeo_View.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/26/25.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct TentGeo_View: View {
    let tent: Tent
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationService = LocationService.shared
    @State private var region: MKCoordinateRegion
    @State private var memberLocations: [String: CLLocationCoordinate2D] = [:]
    @State private var memberUsers: [Users] = []
    @State private var isLoadingLocations = false
    @State private var refreshTimer: Timer?
    @State private var hasAdjustedRegionForUserLocation = false // Track if we've adjusted region for user location
    
    // Drawing mode state
    @State private var isDrawingMode = false
    @State private var boundaryPoints: [CLLocationCoordinate2D] = []
    @State private var isDrawing = false  // Track if currently drawing
    @State private var isSaving = false
    
    // 200 meters radius (fallback if no custom boundary)
    private let tentRadius: CLLocationDistance = 200.0
    
    init(tent: Tent) {
        self.tent = tent
        // Initialize region centered on tent location with appropriate zoom
        let center = CLLocationCoordinate2D(
            latitude: tent.tent_pin_latitude,
            longitude: tent.tent_pin_longitude
        )
        // Set span to show approximately 500 meter radius (1 km total)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        
        // Load existing boundary coordinates if available
        let existingBoundary = tent.boundary_coordinates.map { coord in
            CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        _boundaryPoints = State(initialValue: existingBoundary)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Capacity Indicator at Top
                capacityIndicator
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Map View with Custom Boundary and Member Locations - takes full remaining space
                MapWithBoundaryOverlay(
                    tent: tent,
                    region: $region,
                    radius: tentRadius,
                    memberLocations: memberLocations,
                    memberUsers: memberUsers,
                    boundaryPoints: boundaryPoints,
                    isDrawingMode: isDrawingMode,
                    isDrawing: $isDrawing,
                    onDrawStart: {
                        if isDrawingMode {
                            boundaryPoints.removeAll()
                            isDrawing = true
                        }
                    },
                    onDrawPoint: { coordinate in
                        if isDrawingMode && isDrawing {
                            boundaryPoints.append(coordinate)
                        }
                    },
                    onDrawEnd: {
                        isDrawing = false
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    // Map Controls (Zoom buttons and Location button) - only show when not in drawing mode
                    if !isDrawingMode {
                        VStack(spacing: 8) {
                            // Center on User Location Button
                            if locationService.currentLocation != nil {
                                Button(action: {
                                    if let userLocation = locationService.currentLocation {
                                        withAnimation {
                                            region = MKCoordinateRegion(
                                                center: userLocation.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            )
                                        }
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(Color(.systemBackground))
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                            }
                            
                            // Zoom In Button
                            Button(action: {
                                withAnimation {
                                    let newSpan = MKCoordinateSpan(
                                        latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.001),
                                        longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.001)
                                    )
                                    region = MKCoordinateRegion(center: region.center, span: newSpan)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            
                            // Zoom Out Button
                            Button(action: {
                                withAnimation {
                                    let newSpan = MKCoordinateSpan(
                                        latitudeDelta: min(region.span.latitudeDelta * 2, 180.0),
                                        longitudeDelta: min(region.span.longitudeDelta * 2, 180.0)
                                    )
                                    region = MKCoordinateRegion(center: region.center, span: newSpan)
                                }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                }
                .overlay(alignment: .bottom) {
                    // Info Card at Bottom
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tent.tent_name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Boundary Status Indicator
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(boundaryPoints.isEmpty ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: boundaryPoints.isEmpty ? "location.circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(boundaryPoints.isEmpty ? .red : .green)
                                }
                                
                                Text(boundaryPoints.isEmpty ? "200 m" : "Custom")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(boundaryPoints.isEmpty ? .red : .green)
                            }
                            
                            // Edit Boundary Button
                            Button(action: {
                                withAnimation {
                                    isDrawingMode.toggle()
                                    if !isDrawingMode {
                                        isDrawing = false
                                    }
                                }
                            }) {
                                Image(systemName: isDrawingMode ? "checkmark.circle.fill" : "pencil.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(isDrawingMode ? .green : .blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.leading, 12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(
                        Color(.systemBackground)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                    )
                }
                .overlay(alignment: .top) {
                    // Drawing Mode Controls - positioned near top when active
                    if isDrawingMode {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    boundaryPoints.removeAll()
                                    isDrawing = false
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Clear")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    if !boundaryPoints.isEmpty {
                                        saveBoundary()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark")
                                        Text("Save Boundary")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(boundaryPoints.isEmpty ? Color.gray : Color.green)
                                    .cornerRadius(10)
                                }
                                .disabled(boundaryPoints.isEmpty || isSaving)
                                
                                Button(action: {
                                    isDrawingMode = false
                                    isDrawing = false
                                }) {
                                    Text("Cancel")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(10)
                                }
                            }
                            
                            Text(isDrawing ? "Drawing boundary..." : "Drag your finger on the map to draw the boundary")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.top, 100) // Position below the capacity indicator
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationTitle("Tent Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isDrawingMode && !boundaryPoints.isEmpty {
                    Button(action: {
                        isDrawingMode = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .onAppear {
            // Request location permission and start tracking
            locationService.requestLocationPermission()
            loadMemberLocations()
            startLocationTracking()
            
            // Refresh member locations every 30 seconds
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                loadMemberLocations()
            }
        }
        .onReceive(locationService.$currentLocation) { userLocation in
            // When user location becomes available, optionally adjust map to show both tent and user location
            if let location = userLocation {
                updateRegionToIncludeUserLocation(location.coordinate)
            }
        }
        .onDisappear {
            stopLocationTracking()
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    private func loadMemberLocations() {
        isLoadingLocations = true
        
        // Get all member Firebase UIDs from tent
        var firebaseUIDs: [String] = []
        
        // Get current user's Firebase UID to include their location
        var currentUserFirebaseUID: String?
        if let firebaseUser = AuthenticationManager.shared.currentUser {
            currentUserFirebaseUID = firebaseUser.uid
        }
        
        // Get leader IDs
        for leaderID in tent.leader_id {
            let userDescriptor = FetchDescriptor<Users>(
                predicate: #Predicate<Users> { $0.user_id == leaderID }
            )
            if let user = try? modelContext.fetch(userDescriptor).first,
               let firebaseUID = user.firebaseUID {
                firebaseUIDs.append(firebaseUID)
                if !memberUsers.contains(where: { $0.user_id == user.user_id }) {
                    memberUsers.append(user)
                }
            }
        }
        
        // Get group member IDs
        for groupID in tent.group_id {
            let userDescriptor = FetchDescriptor<Users>(
                predicate: #Predicate<Users> { $0.user_id == groupID }
            )
            if let user = try? modelContext.fetch(userDescriptor).first,
               let firebaseUID = user.firebaseUID {
                firebaseUIDs.append(firebaseUID)
                if !memberUsers.contains(where: { $0.user_id == user.user_id }) {
                    memberUsers.append(user)
                }
            }
        }
        
        // Ensure current user is included
        if let currentUID = currentUserFirebaseUID, !firebaseUIDs.contains(currentUID) {
            firebaseUIDs.append(currentUID)
            // Also add current user to memberUsers if not already there
            let currentUserDescriptor = FetchDescriptor<Users>(
                predicate: #Predicate<Users> { $0.firebaseUID == currentUID }
            )
            if let currentUser = try? modelContext.fetch(currentUserDescriptor).first,
               !memberUsers.contains(where: { $0.user_id == currentUser.user_id }) {
                memberUsers.append(currentUser)
            }
        }
        
        // Fetch locations from Firestore
        Task {
            do {
                let locations = try await LocationService.shared.fetchMemberLocations(firebaseUIDs: firebaseUIDs)
                await MainActor.run {
                    memberLocations = locations
                    isLoadingLocations = false
                }
            } catch {
                await MainActor.run {
                    isLoadingLocations = false
                    print("Error fetching member locations: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Polygon Helper Functions
    
    /// Clean and close polygon points to prevent self-intersections
    static func cleanAndClosePolygon(_ points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard points.count >= 3 else { return points }
        
        var cleaned: [CLLocationCoordinate2D] = []
        let minDistance: CLLocationDistance = 2.0 // Minimum distance in meters
        
        // Remove duplicate/very close points
        for point in points {
            if cleaned.isEmpty {
                cleaned.append(point)
            } else {
                let lastPoint = cleaned.last!
                let distance = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
                    .distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
                
                if distance >= minDistance {
                    cleaned.append(point)
                }
            }
        }
        
        // Ensure we have at least 3 points
        guard cleaned.count >= 3 else { return points }
        
        // Close the polygon by adding the first point at the end if it's not already there
        let first = cleaned.first!
        let last = cleaned.last!
        let distanceToFirst = CLLocation(latitude: last.latitude, longitude: last.longitude)
            .distance(from: CLLocation(latitude: first.latitude, longitude: first.longitude))
        
        if distanceToFirst >= minDistance {
            cleaned.append(first)
        }
        
        return cleaned
    }
    
    private func startLocationTracking() {
        // Get current user's Firebase UID
        guard let firebaseUser = AuthenticationManager.shared.currentUser else { return }
        
        locationService.requestLocationPermission()
        locationService.startTrackingLocation(firebaseUID: firebaseUser.uid)
    }
    
    private func stopLocationTracking() {
        locationService.stopTrackingLocation()
    }
    
    private func updateRegionToIncludeUserLocation(_ userCoordinate: CLLocationCoordinate2D) {
        // Only adjust region once when location first becomes available
        guard !hasAdjustedRegionForUserLocation else { return }
        
        let tentCoordinate = CLLocationCoordinate2D(
            latitude: tent.tent_pin_latitude,
            longitude: tent.tent_pin_longitude
        )
        
        // Check if user location is already visible in current region
        let margin: Double = 0.001 // ~100 meters
        let isUserVisible = abs(userCoordinate.latitude - region.center.latitude) < region.span.latitudeDelta / 2 - margin &&
                           abs(userCoordinate.longitude - region.center.longitude) < region.span.longitudeDelta / 2 - margin
        
        // If user location is not visible, adjust region to include both tent and user location
        if !isUserVisible {
            let centerLat = (tentCoordinate.latitude + userCoordinate.latitude) / 2
            let centerLon = (tentCoordinate.longitude + userCoordinate.longitude) / 2
            
            // Calculate span to include both points with some padding
            let latDelta = abs(tentCoordinate.latitude - userCoordinate.latitude) * 2.5
            let lonDelta = abs(tentCoordinate.longitude - userCoordinate.longitude) * 2.5
            
            let newSpan = MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.005),  // Minimum 500m view
                longitudeDelta: max(lonDelta, 0.005)
            )
            
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: newSpan
                )
            }
        }
        
        hasAdjustedRegionForUserLocation = true
    }
    
    // MARK: - Capacity Indicator
    private var capacityIndicator: some View {
        let currentCount = tent.allMemberIDs.count
        let requiredCount = tent.tent_required_count
        let isFullyStaffed = currentCount >= requiredCount
        
        return HStack(spacing: 12) {
            Image(systemName: isFullyStaffed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundColor(isFullyStaffed ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tent Staffing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(currentCount) / \(requiredCount) people")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isFullyStaffed ? .green : .orange)
            }
            
            Spacer()
            
            if !isFullyStaffed {
                Text("\(requiredCount - currentCount) more needed")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func saveBoundary() {
        guard !boundaryPoints.isEmpty else { return }
        isSaving = true
        
        // Clean and close the polygon before saving
        let cleanedPoints = TentGeo_View.cleanAndClosePolygon(boundaryPoints)
        
        // Convert CLLocationCoordinate2D to BoundaryCoordinate objects
        let boundaryCoords = cleanedPoints.map { coord in
            BoundaryCoordinate(latitude: coord.latitude, longitude: coord.longitude)
        }
        
        // Update local SwiftData model
        tent.boundary_coordinates = boundaryCoords
        
        // Save to Firestore
        Task {
            do {
                guard let firestoreTentID = tent.firestoreTentID else {
                    await MainActor.run {
                        isSaving = false
                        isDrawingMode = false
                    }
                    return
                }
                
                // Update boundary in Firestore
                let db = Firestore.firestore()
                let tentRef = db.collection("tents").document(firestoreTentID)
                
                // Convert coordinates to array of GeoPoints for Firestore
                let geoPoints = cleanedPoints.map { GeoPoint(latitude: $0.latitude, longitude: $0.longitude) }
                
                try await tentRef.updateData([
                    "boundary_coordinates": geoPoints,
                    "updatedAt": Timestamp(date: Date())
                ])
                
                await MainActor.run {
                    isSaving = false
                    isDrawingMode = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("Error saving boundary: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Custom Tent Annotation

class TentAnnotation: NSObject, MKAnnotation {
    let tent: Tent
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(tent: Tent) {
        self.tent = tent
        self.coordinate = CLLocationCoordinate2D(
            latitude: tent.tent_pin_latitude,
            longitude: tent.tent_pin_longitude
        )
        super.init()
        self.title = tent.tent_name
    }
}

// MARK: - Boundary Point Annotation

class BoundaryPointAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    let index: Int
    
    init(coordinate: CLLocationCoordinate2D, index: Int) {
        self.coordinate = coordinate
        self.index = index
        super.init()
        self.title = "Point \(index + 1)"
    }
}

// MARK: - Member Annotation

class MemberAnnotation: NSObject, MKAnnotation {
    let user: Users
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(user: Users, coordinate: CLLocationCoordinate2D) {
        self.user = user
        self.coordinate = coordinate
        super.init()
        if let firstName = user.firstName, let lastName = user.lastName {
            self.title = "\(firstName) \(lastName)"
        } else {
            self.title = user.email
        }
    }
}

// MARK: - Map with Boundary Overlay (Custom View)

struct MapWithBoundaryOverlay: UIViewRepresentable {
    let tent: Tent
    @Binding var region: MKCoordinateRegion
    let radius: CLLocationDistance
    let memberLocations: [String: CLLocationCoordinate2D]
    let memberUsers: [Users]
    let boundaryPoints: [CLLocationCoordinate2D]
    let isDrawingMode: Bool
    @Binding var isDrawing: Bool
    let onDrawStart: () -> Void
    let onDrawPoint: (CLLocationCoordinate2D) -> Void
    let onDrawEnd: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none  // Show user location but don't track
        context.coordinator.mapView = mapView
        context.coordinator.isDrawingMode = isDrawingMode
        context.coordinator.onDrawStart = onDrawStart
        context.coordinator.onDrawPoint = onDrawPoint
        context.coordinator.onDrawEnd = onDrawEnd
        
        // Disable map scrolling when in drawing mode
        mapView.isScrollEnabled = !isDrawingMode
        mapView.isZoomEnabled = !isDrawingMode
        
        // Add tent pin with custom annotation
        let annotation = TentAnnotation(tent: tent)
        mapView.addAnnotation(annotation)
        
        // Add boundary overlay (polygon if custom, circle if default)
        if !boundaryPoints.isEmpty {
            let cleanedPoints = TentGeo_View.cleanAndClosePolygon(boundaryPoints)
            let polygon = MKPolygon(coordinates: cleanedPoints, count: cleanedPoints.count)
            mapView.addOverlay(polygon)
        } else {
            let circle = MKCircle(
                center: annotation.coordinate,
                radius: radius
            )
            mapView.addOverlay(circle)
        }
        
        // Store member data in coordinator for updates
        context.coordinator.memberLocations = memberLocations
        context.coordinator.memberUsers = memberUsers
        context.coordinator.addMemberAnnotations(to: mapView)
        
        // Add pan gesture for continuous drawing (only active when in drawing mode)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = context.coordinator
        panGesture.isEnabled = isDrawingMode  // Only enable when in drawing mode
        context.coordinator.drawingPanGesture = panGesture
        mapView.addGestureRecognizer(panGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update drawing mode
        context.coordinator.isDrawingMode = isDrawingMode
        context.coordinator.onDrawStart = onDrawStart
        context.coordinator.onDrawPoint = onDrawPoint
        context.coordinator.onDrawEnd = onDrawEnd
        
        // Enable/disable drawing gesture based on drawing mode
        context.coordinator.drawingPanGesture?.isEnabled = isDrawingMode
        
        // Disable/enable map scrolling based on drawing mode
        mapView.isScrollEnabled = !isDrawingMode
        mapView.isZoomEnabled = !isDrawingMode
        
        // Update boundary overlay
        mapView.removeOverlays(mapView.overlays.filter { $0 is MKCircle || $0 is MKPolygon })
        
        if !boundaryPoints.isEmpty {
            let cleanedPoints = TentGeo_View.cleanAndClosePolygon(boundaryPoints)
            let polygon = MKPolygon(coordinates: cleanedPoints, count: cleanedPoints.count)
            mapView.addOverlay(polygon)
        } else {
            let annotation = TentAnnotation(tent: tent)
            let circle = MKCircle(center: annotation.coordinate, radius: radius)
            mapView.addOverlay(circle)
        }
        
        // Remove boundary point annotations (we don't show individual points for continuous drawing)
        let boundaryAnnotations = mapView.annotations.filter { $0 is BoundaryPointAnnotation }
        mapView.removeAnnotations(boundaryAnnotations)
        
        // Update member annotations if locations changed
        let locationsChanged = context.coordinator.memberLocations.count != memberLocations.count ||
            Set(context.coordinator.memberLocations.keys) != Set(memberLocations.keys)
        let usersChanged = context.coordinator.memberUsers.count != memberUsers.count
        
        if locationsChanged || usersChanged {
            context.coordinator.memberLocations = memberLocations
            context.coordinator.memberUsers = memberUsers
            context.coordinator.updateMemberAnnotations(on: mapView)
        }
        
        // Only update if region actually changed (to avoid infinite loops)
        let currentCenter = mapView.region.center
        let newCenter = region.center
        let centerChanged = abs(currentCenter.latitude - newCenter.latitude) > 0.0001 ||
                           abs(currentCenter.longitude - newCenter.longitude) > 0.0001
        
        if centerChanged || abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.0001 {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        @Binding var region: MKCoordinateRegion
        var mapView: MKMapView?
        var memberLocations: [String: CLLocationCoordinate2D] = [:]
        var memberUsers: [Users] = []
        private var memberAnnotations: [MemberAnnotation] = []
        var isDrawingMode: Bool = false
        var drawingPanGesture: UIPanGestureRecognizer?
        var onDrawStart: (() -> Void)?
        var onDrawPoint: ((CLLocationCoordinate2D) -> Void)?
        var onDrawEnd: (() -> Void)?
        private var lastPoint: CLLocationCoordinate2D?
        private let minDistance: CLLocationDistance = 5.0  // Minimum distance between points in meters
        
        init(region: Binding<MKCoordinateRegion>) {
            _region = region
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let mapView = mapView, isDrawingMode else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            switch gesture.state {
            case .began:
                onDrawStart?()
                lastPoint = coordinate
                onDrawPoint?(coordinate)
                
            case .changed:
                // Only add point if it's far enough from the last point
                if let last = lastPoint {
                    let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                        .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                    
                    if distance >= minDistance {
                        onDrawPoint?(coordinate)
                        lastPoint = coordinate
                    }
                } else {
                    onDrawPoint?(coordinate)
                    lastPoint = coordinate
                }
                
            case .ended, .cancelled:
                onDrawEnd?()
                lastPoint = nil
                
            default:
                break
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Only allow drawing gesture when in drawing mode
            return isDrawingMode
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // When in drawing mode, don't allow simultaneous recognition - drawing takes priority
            // When NOT in drawing mode, this gesture is disabled, so map gestures work normally
            return false
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // When in drawing mode, our gesture should take priority over map panning
            if isDrawingMode {
                // Check if the other gesture is the map's pan gesture
                if let mapView = mapView {
                    // Get all pan gestures on the map
                    let mapPanGestures = mapView.gestureRecognizers?.filter { $0 is UIPanGestureRecognizer && $0 !== gestureRecognizer } ?? []
                    if mapPanGestures.contains(where: { $0 === otherGestureRecognizer }) {
                        return false  // Don't require failure - we want to intercept
                    }
                }
            }
            return false
        }
        
        func addMemberAnnotations(to mapView: MKMapView) {
            updateMemberAnnotations(on: mapView)
        }
        
        func updateMemberAnnotations(on mapView: MKMapView) {
            // Remove old member annotations
            mapView.removeAnnotations(memberAnnotations)
            memberAnnotations.removeAll()
            
            // Add new member annotations
            for (firebaseUID, coordinate) in memberLocations {
                // Find user for this firebaseUID
                if let user = memberUsers.first(where: { $0.firebaseUID == firebaseUID }) {
                    let annotation = MemberAnnotation(
                        user: user,
                        coordinate: coordinate
                    )
                    memberAnnotations.append(annotation)
                    mapView.addAnnotation(annotation)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circleOverlay)
                circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.15)
                circleRenderer.strokeColor = UIColor.red.withAlphaComponent(0.5)
                circleRenderer.lineWidth = 2
                return circleRenderer
            } else if let polygonOverlay = overlay as? MKPolygon {
                let polygonRenderer = MKPolygonRenderer(polygon: polygonOverlay)
                polygonRenderer.fillColor = UIColor.red.withAlphaComponent(0.15)
                polygonRenderer.strokeColor = UIColor.red.withAlphaComponent(0.5)
                polygonRenderer.lineWidth = 2
                return polygonRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Allow default user location annotation to show
            if annotation is MKUserLocation {
                return nil  // Use default blue dot
            }
            
            // Handle tent annotation
            if let tentAnnotation = annotation as? TentAnnotation {
                let identifier = "TentPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Custom pin view with tent pin code
                let containerView = UIView()
                containerView.frame = CGRect(x: 0, y: 0, width: 60, height: 70)
                
                // Pin icon
                let pinView = UIView()
                pinView.frame = CGRect(x: 10, y: 0, width: 40, height: 40)
                
                // Red circle background
                let circle = UIView()
                circle.frame = pinView.bounds
                circle.backgroundColor = UIColor.red.withAlphaComponent(0.3)
                circle.layer.cornerRadius = 20
                pinView.addSubview(circle)
                
                // Pin icon
                let pinIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
                pinIcon.frame = pinView.bounds
                pinIcon.tintColor = .red
                pinView.addSubview(pinIcon)
                
                containerView.addSubview(pinView)
                
                // Tent pin code badge below pin
                let badge = UILabel()
                badge.text = "\(tentAnnotation.tent.tent_pin)"
                badge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
                badge.textColor = .white
                badge.textAlignment = .center
                badge.backgroundColor = .systemBlue
                badge.layer.cornerRadius = 8
                badge.clipsToBounds = true
                badge.frame = CGRect(x: 0, y: 42, width: 60, height: 20)
                containerView.addSubview(badge)
                
                annotationView?.addSubview(containerView)
                annotationView?.frame = containerView.frame
                annotationView?.centerOffset = CGPoint(x: 0, y: -35)
                
                return annotationView
            }
            
            // Handle member annotation
            if annotation is MemberAnnotation {
                let identifier = "MemberPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Custom member pin view
                let pinView = UIView()
                pinView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
                
                // Blue circle background
                let circle = UIView()
                circle.frame = pinView.bounds
                circle.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
                circle.layer.cornerRadius = 16
                pinView.addSubview(circle)
                
                // Person icon
                let personIcon = UIImageView(image: UIImage(systemName: "person.circle.fill"))
                personIcon.frame = pinView.bounds
                personIcon.tintColor = .blue
                pinView.addSubview(personIcon)
                
                annotationView?.addSubview(pinView)
                annotationView?.frame = pinView.frame
                annotationView?.centerOffset = CGPoint(x: 0, y: -16)
                
                // Title is already set in MemberAnnotation initializer
                
                return annotationView
            }
            
            // Handle boundary point annotation
            if annotation is BoundaryPointAnnotation {
                let identifier = "BoundaryPoint"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Small red dot for boundary point
                let dotView = UIView()
                dotView.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                dotView.backgroundColor = UIColor.red
                dotView.layer.cornerRadius = 8
                dotView.layer.borderWidth = 2
                dotView.layer.borderColor = UIColor.white.cgColor
                
                annotationView?.addSubview(dotView)
                annotationView?.frame = dotView.frame
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                
                return annotationView
            }
            
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TentGeo_View(tent: Tent(
            tent_name: "Sample Tent",
            tent_pin: 123456,
            tent_location: (37.7749, -122.4194), // San Francisco
            tent_required_count: 10
        ))
    }
    .modelContainer(for: [Tent.self], inMemory: true)
}

