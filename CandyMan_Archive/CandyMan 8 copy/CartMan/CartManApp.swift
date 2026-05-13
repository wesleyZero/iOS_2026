//
//  CartManApp.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI
import SwiftData

@main
struct CartManApp: App {
    @State private var viewModel = CartConfigViewModel()
    @State private var systemConfig = SystemConfig()

    let modelContainer: ModelContainer = {
        let schema = Schema([
            SavedCart.self,
            SavedCartTerpene.self,
            CartTemplate.self,
            TemplateTerpene.self,
        ])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let url = config.url
            try? FileManager.default.removeItem(at: url)
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
