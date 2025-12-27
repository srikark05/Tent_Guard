//
//  ProfileCompletionView.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/25/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import Combine

final class ProfileCompletionViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var profileImage: UIImage? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !phone.isEmpty &&
        isValidPhone(phone)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digitsOnly.count >= 10
    }
    
    func phoneToInt() -> Int? {
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digitsOnly)
    }
}

struct ProfileCompletionView: View {
    let email: String
    let firebaseUID: String
    
    @StateObject private var viewModel = ProfileCompletionViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        Text("Complete Your Profile")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Add your profile information to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.secondary)
                        }
                        
                        PhotosPicker(
                            selection: $viewModel.selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(viewModel.profileImage == nil ? "Add Profile Picture" : "Change Picture")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Profile Form
                    VStack(spacing: 20) {
                        // First Name Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("Enter your first name", text: $viewModel.firstName)
                                    .textContentType(.givenName)
                                    .autocapitalization(.words)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.firstName.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Last Name Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("Enter your last name", text: $viewModel.lastName)
                                    .textContentType(.familyName)
                                    .autocapitalization(.words)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.lastName.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Phone Number Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("Enter your phone number", text: $viewModel.phone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                    .onChange(of: viewModel.phone) { _, newValue in
                                        viewModel.phone = formatPhoneNumber(newValue)
                                    }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.phone.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                    
                    // Complete Profile Button
                    Button(action: {
                        completeProfile()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Complete Profile")
                                    .fontWeight(.semibold)
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isValid && !viewModel.isLoading ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: viewModel.isValid ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
            }
        }
        .navigationTitle("Complete Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.profileImage = uiImage
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatPhoneNumber(_ phone: String) -> String {
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if digitsOnly.count > 10 {
            return String(digitsOnly.prefix(10))
        }
        
        if digitsOnly.count >= 6 {
            return String(format: "(%@) %@-%@",
                         String(digitsOnly.prefix(3)),
                         String(digitsOnly.dropFirst(3).prefix(3)),
                         String(digitsOnly.dropFirst(6)))
        } else if digitsOnly.count >= 3 {
            return String(format: "(%@) %@",
                         String(digitsOnly.prefix(3)),
                         String(digitsOnly.dropFirst(3)))
        }
        return digitsOnly
    }
    
    // MARK: - Actions
    
    private func completeProfile() {
        // Guard: Validate phone number
        guard viewModel.isValidPhone(viewModel.phone), let phoneInt = viewModel.phoneToInt() else {
            viewModel.errorMessage = "Please enter a valid phone number"
            return
        }
        
        // Guard: Validate first name
        guard !viewModel.firstName.isEmpty else {
            viewModel.errorMessage = "Please enter your first name"
            return
        }
        
        // Guard: Validate last name
        guard !viewModel.lastName.isEmpty else {
            viewModel.errorMessage = "Please enter your last name"
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        // Convert profile image to Data
        let profilePictureData = viewModel.profileImage?.jpegData(compressionQuality: 0.8)
        
        Task {
            do {
                // Create or update user profile (saves to both Firestore and SwiftData)
                let user = try await AuthenticationManager.shared.createUserProfile(
                    firebaseUID: firebaseUID,
                    email: email,
                    firstName: viewModel.firstName,
                    lastName: viewModel.lastName,
                    phone: phoneInt,
                    profilePicture: profilePictureData,
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    viewModel.isLoading = false
                    print("Profile completed successfully for: \(user.email)")
                    
                    // Navigate to main app (dismiss all authentication views)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileCompletionView(email: "test@example.com", firebaseUID: "test-uid")
    }
}

