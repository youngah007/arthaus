//
//  arthausApp.swift
//  arthaus
//
//  Created by Andrew Young on 4/8/25.
//

import SwiftUI
import SwiftData

@main
struct arthausApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Haus.self,
            ArtPiece.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
