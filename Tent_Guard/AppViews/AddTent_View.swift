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
    @Published var joinTentID: String = ""
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
        !joinTentID.isEmpty
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
                        
                        if let location = viewModel.selectedLocation {
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
            // Tent ID Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tent ID")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter tent ID", text: $viewModel.joinTentID)
                        .textContentType(.none)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.joinTentID.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                )
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
                    viewModel.joinTentID = ""
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
        
        guard let user = currentUser else {
            viewModel.errorMessage = "User not found. Please sign in again."
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        // Create new tent
        let tent = Tent(
            tent_name: viewModel.tentName,
            tent_pin: (location.latitude, location.longitude),
            tent_capacity: capacity,
            tent_users: [user]
        )
        
        // Add tent to user's tent_id array
        user.tent_id.append(tent.id)
        
        // Save to SwiftData
        modelContext.insert(tent)
        
        do {
            try modelContext.save()
            viewModel.isLoading = false
            
            // Navigate to main app or tent view
            dismiss()
        } catch {
            viewModel.isLoading = false
            viewModel.errorMessage = "Failed to create tent: \(error.localizedDescription)"
        }
    }
    
    private func joinTent() {
        guard let tentID = UUID(uuidString: viewModel.joinTentID) else {
            viewModel.errorMessage = "Invalid tent ID format"
            return
        }
        
        guard let user = currentUser else {
            viewModel.errorMessage = "User not found. Please sign in again."
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        // Find tent by ID
        let descriptor = FetchDescriptor<Tent>(
            predicate: #Predicate<Tent> { $0.id == tentID }
        )
        
        if let tent = try? modelContext.fetch(descriptor).first {
            // Check if user is already in tent
            if user.tent_id.contains(tentID) {
                viewModel.errorMessage = "You are already a member of this tent"
                viewModel.isLoading = false
                return
            }
            
            // Check capacity
            if tent.tent_users.count >= tent.tent_capacity {
                viewModel.errorMessage = "Tent is at full capacity"
                viewModel.isLoading = false
                return
            }
            
            // Add user to tent
            tent.add_user(user: user)
            user.tent_id.append(tentID)
            
            do {
                try modelContext.save()
                viewModel.isLoading = false
                
                // Navigate to main app or tent view
                dismiss()
            } catch {
                viewModel.isLoading = false
                viewModel.errorMessage = "Failed to join tent: \(error.localizedDescription)"
            }
        } else {
            viewModel.isLoading = false
            viewModel.errorMessage = "Tent not found. Please check the tent ID."
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

