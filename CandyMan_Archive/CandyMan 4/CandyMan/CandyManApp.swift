//
//  CandyManApp.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI
import SwiftData

@main
struct CandyManApp: App {
    @State private var viewModel = BatchConfigViewModel()
    @State private var systemConfig = SystemConfig()

    let modelContainer: ModelContainer = {
        let schema = Schema([
            SavedBatch.self,
            SavedBatchComponent.self,
            SavedBatchFlavor.self,
            SavedBatchColor.self,
            DryWeightReading.self,
        ])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the store is incompatible with the new schema, delete and retry.
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            // Also remove journal/wal files
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            return try! ModelContainer(for: schema, configurations: [config])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(systemConfig)
        }
        .modelContainer(modelContainer)
    }
}
