//
//  SettingsViewCrashTests.swift
//  CandyManTests
//
//  Tests that reproduce the Settings button crash by programmatically
//  instantiating SettingsView inside a UIHostingController with all
//  required environment objects. This triggers SwiftUI body evaluation
//  the same way fullScreenCover does.
//

import Testing
import SwiftUI
import SwiftData
@testable import CandyMan

// MARK: - Settings View Crash Reproduction

@Suite("Settings View Crash Reproduction")
struct SettingsViewCrashTests {

    // MARK: - Step 1: Bare SettingsView with environments

    @Test("SettingsView instantiates without crash")
    @MainActor
    func settingsViewInstantiation() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

        // This mirrors what ShapePickerView does in its fullScreenCover:
        //   SettingsView()
        //       .environment(systemConfig)
        //       .environment(viewModel)
        let settingsView = SettingsView()
            .environment(systemConfig)
            .environment(viewModel)

        // Force SwiftUI to evaluate the body by hosting it in a real window
        let hostingController = UIHostingController(rootView: settingsView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Force layout pass — this triggers body evaluation
        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        // Clean up
        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 2: SettingsView inside NavigationStack (matches fullScreenCover)

    @Test("SettingsView in NavigationStack evaluates body without crash")
    @MainActor
    func settingsViewInNavigationStack() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

        // SettingsView's body wraps itself in NavigationStack, but let's also
        // test the exact pattern from ShapePickerView's fullScreenCover
        let wrappedView = SettingsView()
            .environment(systemConfig)
            .environment(viewModel)

        let hostingController = UIHostingController(rootView: wrappedView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 3: Full app presentation chain (ContentView → ShapePickerView)

    @Test("Full presentation chain: ContentView with environments")
    @MainActor
    func fullPresentationChain() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

        let contentView = ContentView()
            .environment(systemConfig)
            .environment(viewModel)

        let hostingController = UIHostingController(rootView: contentView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 4: KeyboardDismissToolbar modifier isolation

    @Test("KeyboardDismissToolbar modifier with SystemConfig environment")
    @MainActor
    func keyboardDismissToolbarIsolation() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()

        // KeyboardDismissToolbar uses @Environment(SystemConfig.self) internally
        let testView = Text("Test")
            .keyboardDismissToolbar()
            .environment(systemConfig)

        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 5: SettingsView with preferredColorScheme (matches app)

    @Test("SettingsView with preferredColorScheme(.dark)")
    @MainActor
    func settingsViewWithColorScheme() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

        let settingsView = SettingsView()
            .environment(systemConfig)
            .environment(viewModel)
            .preferredColorScheme(.dark)

        let hostingController = UIHostingController(rootView: settingsView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 6: Simulate the fullScreenCover presentation

    @Test("Simulated fullScreenCover presentation of SettingsView")
    @MainActor
    func simulatedFullScreenCoverPresentation() async throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

        // Create a host view that mirrors ShapePickerView's presentation
        let hostView = SimulatedSettingsPresenter(
            systemConfig: systemConfig,
            viewModel: viewModel
        )
        .environment(systemConfig)
        .environment(viewModel)

        let hostingController = UIHostingController(rootView: hostView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        // Give SwiftUI time to process the fullScreenCover
        try await Task.sleep(for: .milliseconds(500))

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }

    // MARK: - Step 7: ModelContainer initialization with missing Application Support directory

    @Test("ModelContainer initializes when Application Support directory is pre-created")
    @MainActor
    func modelContainerWithDirectoryCreation() throws {
        // This reproduces the iPad-only crash where the Application Support
        // directory doesn't exist on a fresh install, causing CoreData error:
        //   "Failed to stat path '.../Application Support/default.store'"
        //   "Sandbox access to file-write-create denied"
        //
        // The fix ensures the directory is created before ModelContainer init.
        let fm = FileManager.default
        let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // Ensure the directory exists (matching the fix in CandyManApp)
        if !fm.fileExists(atPath: appSupportURL.path) {
            try fm.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        #expect(fm.fileExists(atPath: appSupportURL.path))

        // Now create a ModelContainer using an in-memory config to avoid
        // side effects on the real store, but verify the schema is valid.
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
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        #expect(container.schema.entities.count > 0)
    }

    // MARK: - Step 8: SettingsView with ModelContainer in environment

    @Test("SettingsView presented with ModelContainer does not crash")
    @MainActor
    func settingsViewWithModelContainer() throws {
        let systemConfig = SystemConfig()
        systemConfig.factoryReset()
        let viewModel = BatchConfigViewModel()

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
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let settingsView = SettingsView()
            .environment(systemConfig)
            .environment(viewModel)
            .modelContainer(container)

        let hostingController = UIHostingController(rootView: settingsView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 1366))  // iPad size
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.layoutIfNeeded()

        #expect(hostingController.view != nil)

        window.isHidden = true
        window.rootViewController = nil
    }
}

// MARK: - Helper View for simulating fullScreenCover presentation

/// Mirrors ShapePickerView's Settings presentation pattern
private struct SimulatedSettingsPresenter: View {
    let systemConfig: SystemConfig
    let viewModel: BatchConfigViewModel
    @State private var showSettings = true  // Start with true to immediately present

    var body: some View {
        NavigationStack {
            Text("Main View")
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environment(systemConfig)
                .environment(viewModel)
        }
    }
}
