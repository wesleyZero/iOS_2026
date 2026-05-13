//
//  CandyManApp.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI
import SwiftData

// MARK: - Lock orientation to portrait

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
}

@main
struct CandyManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = BatchConfigViewModel()
    @State private var systemConfig = SystemConfig()
    @State private var iCloudSync = iCloudSyncManager()

    let modelContainer: ModelContainer = {
        let schema = Schema([
            SavedBatch.self,
            SavedBatchComponent.self,
            SavedBatchFlavor.self,
            SavedBatchColor.self,
            DryWeightReading.self,
            BatchTemplate.self,
            TemplateFlavor.self,
            TemplateColor.self,
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
                .environment(iCloudSync)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    iCloudSync.refreshSignInState()
                }
        }
        .modelContainer(modelContainer)
    }
}
