//
//  HomeView.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/26/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [Users]
    @State private var currentUser: Users?
    @State private var showAddTent = false
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                if let user = currentUser, !user.tent_id.isEmpty {
                    // User has tents - show main tent view
                    mainTentView
                } else {
                    // User has no tents - show add tent view
                    NavigationStack {
                        AddTent_View()
                    }
                }
            } else {
                // Not authenticated - show auth view
                NavigationStack {
                    AuthenticationView()
                }
            }
        }
        .onAppear {
            checkAuthentication()
        }
        .onChange(of: AuthenticationManager.shared.currentUser) { _, newValue in
            checkAuthentication()
        }
    }
    
    private var mainTentView: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 8) {
                        Text("Welcome back!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let user = currentUser, let firstName = user.firstName {
                            Text("\(firstName)")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Tent List
                    if let user = currentUser {
                        List {
                            ForEach(user.tent_id, id: \.self) { tentID in
                                TentRowView(tentID: tentID)
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                    
                    // Add Tent Button
                    Button(action: {
                        showAddTent = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add Tent")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Tent Guard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showAddTent) {
                NavigationStack {
                    AddTent_View()
                }
            }
        }
    }
    
    private func checkAuthentication() {
        guard let firebaseUser = AuthenticationManager.shared.currentUser else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        isAuthenticated = true
        let uid = firebaseUser.uid
        
        // Find user in SwiftData
        let descriptor = FetchDescriptor<Users>(
            predicate: #Predicate<Users> { $0.firebaseUID == uid }
        )
        
        if let user = try? modelContext.fetch(descriptor).first {
            currentUser = user
        }
    }
    
    private func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// MARK: - Tent Row View

struct TentRowView: View {
    let tentID: UUID
    @Environment(\.modelContext) private var modelContext
    @State private var tent: Tent?
    
    var body: some View {
        Group {
            if let tent = tent {
                NavigationLink {
                    Text("Tent Details: \(tent.tent_name)")
                        .navigationTitle(tent.tent_name)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "tent.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tent.tent_name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(tent.tent_users.count) / \(tent.tent_capacity) members")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("Loading tent...")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadTent()
        }
    }
    
    private func loadTent() {
        let descriptor = FetchDescriptor<Tent>(
            predicate: #Predicate<Tent> { $0.id == tentID }
        )
        
        if let foundTent = try? modelContext.fetch(descriptor).first {
            tent = foundTent
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Users.self, Tent.self], inMemory: true)
}

