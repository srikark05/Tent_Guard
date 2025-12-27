//
//  SignInView.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/25/25.
//

import SwiftUI
import Combine
import SwiftData

final class SignInEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct SignInView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
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
                        Image(systemName: "tent.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to continue to Tent Guard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                    
                    // Sign In Form
                    VStack(spacing: 24) {
                        // Email Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("Enter your email", text: $viewModel.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.email.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Password Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                if viewModel.isPasswordVisible {
                                    TextField("Enter your password", text: $viewModel.password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $viewModel.password)
                                        .textContentType(.password)
                                }
                                
                                Button(action: {
                                    viewModel.isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.password.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
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
                    
                    // Sign In Button
                    Button(action: {
                        signIn()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
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
                    
                    // Forgot Password Link
                    Button(action: {
                        // TODO: Navigate to forgot password
                    }) {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 32)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func signIn() {
        // Guard: Validate email format
        guard viewModel.isValidEmail(viewModel.email) else {
            viewModel.errorMessage = "Please sign in with a valid email address"
            return
        }
        
        // Guard: Validate password is not empty
        guard !viewModel.password.isEmpty else {
            viewModel.errorMessage = "Please enter your password"
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        Task {
            do {
                // Step 1: Sign in with Firebase Auth
                let authResult = try await AuthenticationManager.shared.signIn(
                    email: viewModel.email,
                    password: viewModel.password
                )
                
                // Step 2: Fetch profile data from Firestore and sync to SwiftData
                do {
                    let user = try await AuthenticationManager.shared.syncProfileFromFirestore(
                        firebaseUID: authResult.uid,
                        email: authResult.email ?? viewModel.email,
                        modelContext: modelContext
                    )
                    
                    await MainActor.run {
                        viewModel.isLoading = false
                        print("User signed in successfully: \(user.email)")
                        print("Profile synced: \(user.firstName ?? "N/A") \(user.lastName ?? "N/A")")
                        // Success - user signed in and profile synced
                        dismiss()
                    }
                } catch {
                    // If profile doesn't exist in Firestore yet, that's okay
                    // User might need to complete their profile
                    await MainActor.run {
                        viewModel.isLoading = false
                        print("User signed in successfully, but profile not found in Firestore")
                        print("This is normal for new users who haven't completed their profile yet")
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.isLoading = false
                    // Provide user-friendly error messages
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case 17008: // Invalid email
                            viewModel.errorMessage = "Please sign in with a valid email address"
                        case 17009, 17010, 17011: // Wrong password, too many attempts, etc.
                            viewModel.errorMessage = "Invalid email or password. Please try again."
                        case 17020: // Network error
                            viewModel.errorMessage = "Network error. Please check your connection."
                        default:
                            viewModel.errorMessage = error.localizedDescription
                        }
                    } else {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignInView()
    }
}
