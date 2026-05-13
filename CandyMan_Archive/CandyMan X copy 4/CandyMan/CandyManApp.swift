//
//  CandyManApp.swift
//  CandyMan
//
//  App entry point. Locks orientation to portrait, creates the SwiftData
//  ModelContainer with all model types, and injects the @Observable
//  singletons — BatchConfigViewModel, SystemConfig — into the environment.
//  If the persistent store is incompatible with the current schema, it is
//  automatically deleted and recreated.
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

/// Wrapper to make a crash report string identifiable for `.sheet(item:)`.
private struct CrashReportItem: Identifiable {
    let id = UUID()
    let report: String
}

@main
struct CandyManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = BatchConfigViewModel()
    @State private var systemConfig = SystemConfig()
    @State private var crashReport: String? = nil

    init() {
        ScribbleKiller.install()
        CrashReporter.shared.install()
    }

    let modelContainer: ModelContainer = {
        let schema = Schema([
            SavedBatch.self,
            SavedBatchComponent.self,
            SavedBatchFlavor.self,
            SavedBatchColor.self,
            DehydrationContainer.self,
            DryWeightReading.self,
            TareWeightRecord.self,
            BatchTemplate.self,
            TemplateFlavor.self,
            TemplateColor.self,
            AdditionalMeasurementEntry.self,
            BatchRequest.self,
        ])
        let config = ModelConfiguration(schema: schema)

        // Ensure the Application Support directory exists before SwiftData
        // tries to create the SQLite store file. On physical devices (especially
        // iPad) a fresh install may not have this directory yet, causing a
        // "Failed to create file; code = 2" CoreData error.
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the store is incompatible with the current schema, delete and retry.
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            // Also remove journal/wal files
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(systemConfig)
                .preferredColorScheme(.dark)
                .onAppear {
                    CrashReporter.shared.captureEnvironment(from: systemConfig)
                    crashReport = CrashReporter.shared.consumeLastCrashReport()
                }
                .sheet(item: Binding(
                    get: { crashReport.map { CrashReportItem(report: $0) } },
                    set: { newValue in if newValue == nil { crashReport = nil } }
                )) { item in
                    CrashReportView(report: item.report) { crashReport = nil }
                }
        }
        .modelContainer(modelContainer)
    }
}
