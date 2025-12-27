//
//  AuthenticationView.swift
//  Tent_Guard
//
//  Created on 12/25/25.
//

import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Welcome Section
                VStack(spacing: 24) {
                    // App Icon/Logo
                    Image(systemName: "tent.2.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.bottom, 8)
                    
                    // App Name
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Tent Guard")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Tagline
                    Text("Manage your tent schedules with ease")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                .padding(.bottom, 80)
                
                Spacer()
                
                // Action Buttons Section
                VStack(spacing: 16) {
                    // Sign Up Button
                    NavigationLink(destination: SignUpView()) {
                        HStack {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Sign In Button
                    NavigationLink(destination: SignInView()) {
                        HStack {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Custom Button Style

/// Button style that provides a subtle scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AuthenticationView()
    }
}

