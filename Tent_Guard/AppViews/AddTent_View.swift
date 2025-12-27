//
//  AddTent_View.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/26/25.
//

import SwiftUI
import SwiftData
import MapKit
import Combine
import FirebaseAuth

final class AddTentViewModel: ObservableObject {
    @Published var tentName: String = ""
    @Published var tentCapacity: String = ""
    @Published var joinTentPin: String = ""
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var isCreatingTent: Bool = false
    @Published var isJoiningTent: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showMapPicker: Bool = false
    
    var isValidCreate: Bool {
        !tentName.isEmpty &&
        !tentCapacity.isEmpty &&
        Int(tentCapacity) != nil &&
        selectedLocation != nil
    }
    
    var isValidJoin: Bool {
        !joinTentPin.isEmpty && joinTentPin.count == 6 && Int(joinTentPin) != nil
    }
    
    func capacityToInt() -> Int? {
        return Int(tentCapacity)
    }
}

struct AddTent_View: View {
    @StateObject private var viewModel = AddTentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [Users]
    @State private var currentUser: Users?
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "tent.2.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            .padding(.top, 20)
                        
                        Text("Welcome to Tent Guard")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Create a new tent or join an existing one")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 8)
                    
                    // Action Buttons Section
                    VStack(spacing: 20) {
                        // Create Tent Button
                        Button(action: {
                            withAnimation {
                                viewModel.isCreatingTent = true
                                viewModel.isJoiningTent = false
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create New Tent")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("Start a new tent schedule")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Join Tent Button
                        Button(action: {
                            withAnimation {
                                viewModel.isJoiningTent = true
                                viewModel.isCreatingTent = false
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Join Existing Tent")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Enter tent ID to join")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    // Create Tent Form
                    if viewModel.isCreatingTent {
                        createTentForm
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Join Tent Form
                    if viewModel.isJoiningTent {
                        joinTentForm
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 32)
            }
        }
        .navigationTitle("Add Tent")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showMapPicker) {
            MapLocationPickerView(selectedLocation: $viewModel.selectedLocation)
        }
        .onAppear {
            loadCurrentUser()
        }
    }
    
    // MARK: - Create Tent Form
    
    private var createTentForm: some View {
        VStack(spacing: 20) {
            // Tent Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tent Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "tent.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter tent name", text: $viewModel.tentName)
                        .textContentType(.organizationName)
                        .autocapitalization(.words)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.tentName.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Tent Capacity Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Capacity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter capacity", text: $viewModel.tentCapacity)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.tentCapacity.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Location Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Tent Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Button(action: {
                    viewModel.showMapPicker = true
                }) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        if viewModel.selectedLocation != nil {
                            Text("Location Selected")
                                .foregroundColor(.primary)
                        } else {
                            Text("Select Location on Map")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedLocation == nil ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
            
            // Create Button
            Button(action: {
                createTent()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Tent")
                            .fontWeight(.semibold)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isValidCreate && !viewModel.isLoading ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: viewModel.isValidCreate ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.isValidCreate || viewModel.isLoading)
            .buttonStyle(ScaleButtonStyle())
            
            // Cancel Button
            Button(action: {
                withAnimation {
                    viewModel.isCreatingTent = false
                    viewModel.tentName = ""
                    viewModel.tentCapacity = ""
                    viewModel.selectedLocation = nil
                    viewModel.errorMessage = nil
                }
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    // MARK: - Join Tent Form
    
    private var joinTentForm: some View {
        VStack(spacing: 20) {
            // Tent Pin Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tent Pin")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter 6-digit pin", text: $viewModel.joinTentPin)
                        .textContentType(.none)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.joinTentPin) { _, newValue in
                            // Limit to 6 digits
                            let digitsOnly = newValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if digitsOnly.count > 6 {
                                viewModel.joinTentPin = String(digitsOnly.prefix(6))
                            } else {
                                viewModel.joinTentPin = digitsOnly
                            }
                        }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.joinTentPin.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                if !viewModel.joinTentPin.isEmpty && viewModel.joinTentPin.count != 6 {
                    Text("Pin must be 6 digits")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
            
            // Join Button
            Button(action: {
                joinTent()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Join Tent")
                            .fontWeight(.semibold)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isValidJoin && !viewModel.isLoading ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: viewModel.isValidJoin ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.isValidJoin || viewModel.isLoading)
            .buttonStyle(ScaleButtonStyle())
            
            // Cancel Button
            Button(action: {
                withAnimation {
                    viewModel.isJoiningTent = false
                    viewModel.joinTentPin = ""
                    viewModel.errorMessage = nil
                }
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    private func loadCurrentUser() {
        // Get current Firebase user
        guard let firebaseUser = AuthenticationManager.shared.currentUser else { return }
        
        let uid = firebaseUser.uid
        // Find user in SwiftData by firebaseUID
        let descriptor = FetchDescriptor<Users>(
            predicate: #Predicate<Users> { $0.firebaseUID == uid }
        )
        
        if let user = try? modelContext.fetch(descriptor).first {
            currentUser = user
        }
    }
    
    // MARK: - Actions
    
    private func createTent() {
        guard let capacity = viewModel.capacityToInt() else {
            viewModel.errorMessage = "Please enter a valid capacity"
            return
        }
        
        guard let location = viewModel.selectedLocation else {
            viewModel.errorMessage = "Please select a location"
            return
        }
        
        guard let user = currentUser, let firebaseUID = user.firebaseUID else {
            viewModel.errorMessage = "User not found. Please sign in again."
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        Task {
            do {
                // Generate 6-digit pin
                let tentPin = AuthenticationManager.shared.generateTentPin()
                
                // Create tent ID
                let tentID = UUID()
                let tentIDString = tentID.uuidString
                
                // Step 1: Save tent to Firestore
                let firestoreTentID = try await AuthenticationManager.shared.saveTentToFirestore(
                    tentID: tentID,
                    tentName: viewModel.tentName,
                    tentPin: tentPin,
                    tentLocation: (location.latitude, location.longitude),
                    tentCapacity: capacity,
                    leaderID: user.user_id,
                    firebaseUID: firebaseUID
                )
                
                // Step 2: Add tent ID to user's tent_ids in Firestore
                try await AuthenticationManager.shared.addTentIDToUser(
                    firebaseUID: firebaseUID,
                    tentID: tentIDString
                )
                
                // Step 3: Create SwiftData Tent object
                // Note: leader_id in SwiftData stores user.user_id (UUID), not firebaseUID
                let tent = Tent(
                    id: tentID,
                    firestoreTentID: firestoreTentID,
                    tent_name: viewModel.tentName,
                    tent_pin: tentPin,
                    tent_location: (location.latitude, location.longitude),
                    tent_capacity: capacity,
                    leader_id: [user.user_id],  // SwiftData uses UUID
                    group_id: [],
                    tent_users: [user]
                )
                
                // Step 4: Add tent to user's tent_id array in SwiftData
                user.tent_id.append(tent.id)
                
                // Step 5: Save to SwiftData
                modelContext.insert(tent)
                try modelContext.save()
                
                await MainActor.run {
                    viewModel.isLoading = false
                    // Navigate to main app or tent view
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    viewModel.errorMessage = "Failed to create tent: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func joinTent() {
        guard let tentPinInt = Int(viewModel.joinTentPin), viewModel.joinTentPin.count == 6 else {
            viewModel.errorMessage = "Please enter a valid 6-digit pin"
            return
        }
        
        guard let user = currentUser, let firebaseUID = user.firebaseUID else {
            viewModel.errorMessage = "User not found. Please sign in again."
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        Task {
            do {
                // Step 1: Fetch tent from Firestore by pin
                guard let tentData = try await AuthenticationManager.shared.fetchTentByPin(tentPin: tentPinInt) else {
                    await MainActor.run {
                        viewModel.isLoading = false
                        viewModel.errorMessage = "Tent not found. Please check the pin."
                    }
                    return
                }
                
                guard let tentIDString = tentData["tent_id"] as? String,
                      let tentID = UUID(uuidString: tentIDString) else {
                    await MainActor.run {
                        viewModel.isLoading = false
                        viewModel.errorMessage = "Invalid tent data"
                    }
                    return
                }
                
                // Step 2: Check if user is already in tent
                if user.tent_id.contains(tentID) {
                    await MainActor.run {
                        viewModel.isLoading = false
                        viewModel.errorMessage = "You are already a member of this tent"
                    }
                    return
                }
                
                // Step 3: Check if tent is at capacity
                let isAtCapacity = try await AuthenticationManager.shared.isTentAtCapacity(tentID: tentIDString)
                if isAtCapacity {
                    await MainActor.run {
                        viewModel.isLoading = false
                        viewModel.errorMessage = "Tent is at full capacity"
                    }
                    return
                }
                
                // Step 4: Add user to tent's group_id in Firestore
                try await AuthenticationManager.shared.addUserToTentGroup(
                    tentID: tentIDString,
                    firebaseUID: firebaseUID
                )
                
                // Step 5: Add tent ID to user's tent_ids in Firestore
                try await AuthenticationManager.shared.addTentIDToUser(
                    firebaseUID: firebaseUID,
                    tentID: tentIDString
                )
                
                // Step 6: Update or create tent in SwiftData
                let descriptor = FetchDescriptor<Tent>(
                    predicate: #Predicate<Tent> { $0.id == tentID }
                )
                
                let tent: Tent
                if let existingTent = try? modelContext.fetch(descriptor).first {
                    tent = existingTent
                } else {
                    // Create new tent from Firestore data
                    let tentName = tentData["tent_name"] as? String ?? "Unknown Tent"
                    let tentPin = tentData["tent_pin"] as? Int ?? tentPinInt
                    let latitude = tentData["tent_pin_latitude"] as? Double ?? 0.0
                    let longitude = tentData["tent_pin_longitude"] as? Double ?? 0.0
                    let capacity = tentData["tent_capacity"] as? Int ?? 10
                    
                    // Convert Firebase UIDs to user UUIDs by looking up users
                    let leaderFirebaseUIDs = tentData["leader_id"] as? [String] ?? []
                    let groupFirebaseUIDs = tentData["group_id"] as? [String] ?? []
                    
                    var leaderIDs: [UUID] = []
                    var groupIDs: [UUID] = []
                    
                    // Look up users by firebaseUID to get their user_id (UUID)
                    for firebaseUID in leaderFirebaseUIDs {
                        let userDescriptor = FetchDescriptor<Users>(
                            predicate: #Predicate<Users> { $0.firebaseUID == firebaseUID }
                        )
                        if let foundUser = try? modelContext.fetch(userDescriptor).first {
                            leaderIDs.append(foundUser.user_id)
                        }
                    }
                    
                    for firebaseUID in groupFirebaseUIDs {
                        let userDescriptor = FetchDescriptor<Users>(
                            predicate: #Predicate<Users> { $0.firebaseUID == firebaseUID }
                        )
                        if let foundUser = try? modelContext.fetch(userDescriptor).first {
                            groupIDs.append(foundUser.user_id)
                        }
                    }
                    
                    // Get boundary coordinates if available
                    var boundaryCoords: [(Double, Double)] = []
                    if let boundaryData = tentData["boundary_coordinates"] as? [(Double, Double)] {
                        boundaryCoords = boundaryData
                    }
                    
                    tent = Tent(
                        id: tentID,
                        firestoreTentID: tentIDString,
                        tent_name: tentName,
                        tent_pin: tentPin,
                        tent_location: (latitude, longitude),
                        tent_capacity: capacity,
                        leader_id: leaderIDs,
                        group_id: groupIDs,
                        tent_users: [],
                        boundary_coordinates: boundaryCoords  // Will be converted to BoundaryCoordinate in init
                    )
                    modelContext.insert(tent)
                }
                
                // Step 7: Add user to tent in SwiftData
                tent.add_group_member(userID: user.user_id)
                user.tent_id.append(tentID)
                
                // Step 8: Save to SwiftData
                try modelContext.save()
                
                await MainActor.run {
                    viewModel.isLoading = false
                    // Navigate to main app or tent view
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    viewModel.errorMessage = "Failed to join tent: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Map Location Picker View

struct MapLocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showSearchResults = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: false)
                
                // Center pin indicator
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 100)
                
                // Search Bar Overlay
                VStack {
                    VStack(spacing: 0) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search for address or location", text: $searchText)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    searchLocation()
                                }
                                .onChange(of: searchText) { _, newValue in
                                    if !newValue.isEmpty {
                                        showSearchResults = true
                                    } else {
                                        showSearchResults = false
                                        searchResults.removeAll()
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults.removeAll()
                                    showSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        
                        // Search Results
                        if showSearchResults && !searchResults.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(searchResults, id: \.self) { mapItem in
                                        Button(action: {
                                            selectSearchResult(mapItem)
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.blue)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(mapItem.name ?? "Unknown")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    
                                                    if let address = mapItem.placemark.title {
                                                        Text(address)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(2)
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select") {
                        selectedLocation = region.center
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    return
                }
                
                if let response = response {
                    searchResults = response.mapItems
                    showSearchResults = true
                }
            }
        }
    }
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        
        // Update region to center on selected location
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        // Update selected location
        selectedLocation = coordinate
        
        // Clear search
        searchText = ""
        searchResults.removeAll()
        showSearchResults = false
    }
}

// MARK: - Map Annotation

struct MapAnnotation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddTent_View()
    }
    .modelContainer(for: [Users.self, Tent.self], inMemory: true)
}

