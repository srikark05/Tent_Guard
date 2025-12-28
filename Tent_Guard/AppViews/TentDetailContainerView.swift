//
//  TentDetailContainerView.swift
//  Tent_Guard
//
//  Created on 12/27/25.
//

import SwiftUI

struct TentDetailContainerView: View {
    let tent: Tent
    @State private var selectedTab: TabOption = .map
    @State private var isMenuOpen = false // Track menu dropdown state
    
    enum TabOption: String, CaseIterable {
        case map = "Map"
        case schedule = "Schedule"
        case shifts = "Shifts"
        
        var icon: String {
            switch self {
            case .map:
                return "map.fill"
            case .schedule:
                return "calendar"
            case .shifts:
                return "clock.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Semi-transparent backdrop when menu is open
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuOpen = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            // Content View
            Group {
                switch selectedTab {
                case .map:
                    TentGeo_View(tent: tent)
                case .schedule:
                    ScheduleBuilder_View(tent: tent)
                case .shifts:
                    ScheduleShift_View(tent: tent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .trailing) {
                // Right Menu Dropdown
                if isMenuOpen {
                    VStack(alignment: .leading, spacing: 20) {
                        // Menu Header
                        HStack {
                            Text("Tent Info")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isMenuOpen = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Tent Pin Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tent Pin")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(tent.tent_pin)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .frame(width: 280)
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: -5, y: 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(2)
                }
            }
            
            // Tab Bar
            tabBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Menu Button - Top Right in Navigation Bar
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isMenuOpen.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabOption.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
}

