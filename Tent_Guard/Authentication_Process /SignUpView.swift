//
//  SignUpView.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/25/25.
//

import SwiftUI
import Combine
import SwiftData

final class SignUpEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        !email.isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        password.count >= 6 &&
        passwordsMatch
    }
    
    var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    var isEmailValid: Bool {
        isValidEmail(email)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct SignUpView: View {
    @StateObject private var viewModel = SignUpEmailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToProfileCompletion = false
    @State private var signedUpEmail: String = ""
    @State private var signedUpUID: String = ""
    
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
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign up to start managing your tent schedules")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                    
                    // Sign Up Form
                    VStack(spacing: 20) {
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
                                    .stroke(viewModel.email.isEmpty ? Color.clear : (viewModel.isEmailValid ? Color.blue.opacity(0.3) : Color.red.opacity(0.3)), lineWidth: 1)
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
                                    TextField("Create a password", text: $viewModel.password)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Create a password", text: $viewModel.password)
                                        .textContentType(.newPassword)
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
                                    .stroke(viewModel.password.isEmpty ? Color.clear : (viewModel.password.count >= 6 ? Color.blue.opacity(0.3) : Color.red.opacity(0.3)), lineWidth: 1)
                            )
                            
                            if !viewModel.password.isEmpty && viewModel.password.count < 6 {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Confirm Password Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                if viewModel.isConfirmPasswordVisible {
                                    TextField("Confirm your password", text: $viewModel.confirmPassword)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Confirm your password", text: $viewModel.confirmPassword)
                                        .textContentType(.newPassword)
                                }
                                
                                Button(action: {
                                    viewModel.isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.confirmPassword.isEmpty ? Color.clear : (viewModel.passwordsMatch ? Color.blue.opacity(0.3) : Color.red.opacity(0.3)), lineWidth: 1)
                            )
                            
                            if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
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
                    
                    // Sign Up Button
                    Button(action: {
                        signUp()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
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
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToProfileCompletion) {
            ProfileCompletionView(email: signedUpEmail, firebaseUID: signedUpUID)
        }
    }
    
    // MARK: - Actions
    
    private func signUp() {
        // Guard: Validate email format
        guard viewModel.isValidEmail(viewModel.email) else {
            viewModel.errorMessage = "Please enter a valid email address"
            return
        }
        
        // Guard: Validate password length
        guard viewModel.password.count >= 6 else {
            viewModel.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        // Guard: Validate passwords match
        guard viewModel.passwordsMatch else {
            viewModel.errorMessage = "Passwords do not match"
            return
        }
        
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        Task {
            do {
                // Create Firebase Auth account (email/password only)
                let authResult = try await AuthenticationManager.shared.createUser(
                    email: viewModel.email,
                    password: viewModel.password
                )
                
                await MainActor.run {
                    viewModel.isLoading = false
                    // Navigate to profile completion page
                    signedUpEmail = viewModel.email
                    signedUpUID = authResult.uid
                    navigateToProfileCompletion = true
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
    SignUpView()
    }
}
