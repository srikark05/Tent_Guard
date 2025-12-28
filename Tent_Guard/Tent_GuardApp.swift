//
//  Tent_GuardApp.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/20/25.
//

import SwiftUI
import SwiftData
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct Tent_GuardApp: App {
    
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Users.self,
            Tent.self,
            BoundaryCoordinate.self,
            User_Schedule.self,
            Tent_Schedule.self,
            Gap_Schedule.self,
        ])
        
        // Use versioned database name to handle schema changes
        // Increment version number when schema changes significantly
        let databaseVersion = 2  // Increment this when schema changes
        let databaseName = "TentGuard_v\(databaseVersion)"
        
        // Create custom URL for the database
        let databaseURL = URL.applicationSupportDirectory.appending(component: "\(databaseName).store")
        
        // Create ModelConfiguration with custom URL
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If schema migration fails, try to delete old database files and recreate
            print("ModelContainer creation failed: \(error)")
            print("Attempting to reset database due to schema change...")
            
            do {
                // Delete old database files
                let dbShmURL = databaseURL.appendingPathExtension("shm")
                let dbWalURL = databaseURL.appendingPathExtension("wal")
                
                for url in [databaseURL, dbShmURL, dbWalURL] {
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.removeItem(at: url)
                        print("Deleted old database file: \(url.path)")
                    }
                }
                
                // Create new container with fresh database
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // If that also fails, use in-memory storage as fallback
                print("Failed to reset database, using in-memory storage: \(error)")
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
