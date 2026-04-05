//
//  CrashReporter.swift
//  CandyMan
//
//  Captures uncaught exceptions and Unix signals, writes a verbose crash
//  report to disk, and provides a SwiftUI view to display the report on
//  the next launch. Reports include: stack trace, device info, memory
//  stats, active view context, thread info, and environment snapshot.
//

import Foundation
import SwiftUI
import os

// MARK: - CrashReporter

/// Singleton that installs global crash handlers and manages crash log files.
final class CrashReporter {
    static let shared = CrashReporter()

    // Where the crash report is written (Application Support directory)
    private let crashLogURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("CandyMan_CrashReport.log")
    }()

    // In-memory breadcrumbs: the last N user actions before a crash
    private var breadcrumbs: [(timestamp: Date, event: String)] = []
    private let maxBreadcrumbs = 50
    private let lock = NSLock()

    /// The currently active view/screen name, set by the app as the user navigates.
    var activeScreen: String = "Unknown"

    /// Additional context dictionary the app can populate (e.g. SystemConfig snapshot).
    var environmentSnapshot: [String: String] = [:]

    private init() {}

    // MARK: - Installation

    /// Install global crash handlers. Call once at app startup.
    func install() {
        // 1. NSException handler (Objective-C exceptions)
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleException(exception)
        }

        // 2. Unix signal handlers for common crash signals
        let signals: [Int32] = [SIGABRT, SIGILL, SIGTRAP, SIGSEGV, SIGFPE, SIGBUS]
        for sig in signals {
            signal(sig) { signalNumber in
                CrashReporter.shared.handleSignal(signalNumber)
            }
        }

        addBreadcrumb("CrashReporter installed")
    }

    // MARK: - Breadcrumbs

    /// Record a user action or navigation event as a breadcrumb.
    func addBreadcrumb(_ event: String) {
        lock.lock()
        defer { lock.unlock() }
        breadcrumbs.append((Date(), event))
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst()
        }
    }

    // MARK: - Crash Handlers

    private func handleException(_ exception: NSException) {
        let report = buildReport(
            crashType: "Uncaught NSException",
            name: exception.name.rawValue,
            reason: exception.reason ?? "No reason provided",
            callStack: exception.callStackSymbols
        )
        writeReport(report)
    }

    private func handleSignal(_ signal: Int32) {
        let signalName: String
        switch signal {
        case SIGABRT: signalName = "SIGABRT (Abort)"
        case SIGILL:  signalName = "SIGILL (Illegal instruction)"
        case SIGTRAP: signalName = "SIGTRAP (Trace trap)"
        case SIGSEGV: signalName = "SIGSEGV (Segmentation fault)"
        case SIGFPE:  signalName = "SIGFPE (Floating-point exception)"
        case SIGBUS:  signalName = "SIGBUS (Bus error)"
        default:      signalName = "Signal \(signal)"
        }

        // Capture current thread's call stack
        let callStack = Thread.callStackSymbols

        let report = buildReport(
            crashType: "Unix Signal",
            name: signalName,
            reason: "Process received fatal signal",
            callStack: callStack
        )
        writeReport(report)

        // Re-raise to let the system produce the standard crash log too
        let defaultAction = SIG_DFL
        Foundation.signal(signal, defaultAction)
        raise(signal)
    }

    // MARK: - Report Builder

    private func buildReport(
        crashType: String,
        name: String,
        reason: String,
        callStack: [String]
    ) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let device = deviceInfo()
        let memory = memoryInfo()
        let threads = threadInfo()

        var report = """
        ╔══════════════════════════════════════════════════════════════╗
        ║              CANDYMAN VERBOSE CRASH REPORT                  ║
        ╚══════════════════════════════════════════════════════════════╝

        Timestamp:     \(timestamp)
        Crash Type:    \(crashType)
        Name:          \(name)
        Reason:        \(reason)
        Active Screen: \(activeScreen)

        ────────────────────────────────────────────────────────────────
        DEVICE INFO
        ────────────────────────────────────────────────────────────────
        \(device)

        ────────────────────────────────────────────────────────────────
        MEMORY
        ────────────────────────────────────────────────────────────────
        \(memory)

        ────────────────────────────────────────────────────────────────
        THREAD INFO
        ────────────────────────────────────────────────────────────────
        \(threads)

        ────────────────────────────────────────────────────────────────
        STACK TRACE (\(callStack.count) frames)
        ────────────────────────────────────────────────────────────────
        """

        for (i, frame) in callStack.enumerated() {
            report += "\n  [\(i)] \(frame)"
        }

        // Breadcrumbs
        lock.lock()
        let crumbs = breadcrumbs
        lock.unlock()

        report += """
        \n
        ────────────────────────────────────────────────────────────────
        BREADCRUMBS (last \(crumbs.count) events)
        ────────────────────────────────────────────────────────────────
        """

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        for crumb in crumbs {
            report += "\n  [\(formatter.string(from: crumb.timestamp))] \(crumb.event)"
        }

        // Environment snapshot
        if !environmentSnapshot.isEmpty {
            report += """
            \n
            ────────────────────────────────────────────────────────────────
            ENVIRONMENT SNAPSHOT
            ────────────────────────────────────────────────────────────────
            """
            for (key, value) in environmentSnapshot.sorted(by: { $0.key < $1.key }) {
                report += "\n  \(key): \(value)"
            }
        }

        report += "\n\n══════════════════ END OF CRASH REPORT ══════════════════\n"
        return report
    }

    // MARK: - Device Info

    private func deviceInfo() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }

        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo

        return """
        Model:            \(machine)
        Name:             \(device.name)
        System:           \(device.systemName) \(device.systemVersion)
        Idiom:            \(device.userInterfaceIdiom == .pad ? "iPad" : "iPhone")
        Process:          \(processInfo.processName) (PID \(processInfo.processIdentifier))
        OS Uptime:        \(String(format: "%.0f", processInfo.systemUptime)) seconds
        Processor Count:  \(processInfo.processorCount) cores
        Active Cores:     \(processInfo.activeProcessorCount)
        Physical Memory:  \(processInfo.physicalMemory / 1_048_576) MB
        Thermal State:    \(thermalStateLabel(processInfo.thermalState))
        Low Power Mode:   \(processInfo.isLowPowerModeEnabled ? "YES" : "NO")
        """
    }

    private func thermalStateLabel(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "Nominal"
        case .fair:     return "Fair"
        case .serious:  return "Serious"
        case .critical: return "CRITICAL"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Memory Info

    private func memoryInfo() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let residentMB = Double(info.resident_size) / 1_048_576.0
            let virtualMB = Double(info.virtual_size) / 1_048_576.0
            return """
            Resident Memory:  \(String(format: "%.1f", residentMB)) MB
            Virtual Memory:   \(String(format: "%.1f", virtualMB)) MB
            """
        } else {
            return "Memory info unavailable (kern result: \(result))"
        }
    }

    // MARK: - Thread Info

    private func threadInfo() -> String {
        let current = Thread.current
        let isMain = current.isMainThread
        let qosClass: String
        switch current.qualityOfService {
        case .userInteractive: qosClass = "User Interactive"
        case .userInitiated:   qosClass = "User Initiated"
        case .default:         qosClass = "Default"
        case .utility:         qosClass = "Utility"
        case .background:      qosClass = "Background"
        @unknown default:      qosClass = "Unknown"
        }

        return """
        Main Thread:      \(isMain ? "YES" : "NO")
        Thread Name:      \(current.name ?? "(unnamed)")
        QoS Class:        \(qosClass)
        Stack Size:       \(current.stackSize / 1024) KB
        """
    }

    // MARK: - File I/O

    private func writeReport(_ report: String) {
        // Use synchronous, low-level write to survive crash context
        let data = Data(report.utf8)
        try? data.write(to: crashLogURL, options: .atomic)

        // Also log to os_log for Console.app visibility
        os_log(.fault, "CandyMan Crash Report written to: %{public}@", crashLogURL.path)
    }

    /// Returns the last crash report if one exists, then deletes it.
    func consumeLastCrashReport() -> String? {
        guard FileManager.default.fileExists(atPath: crashLogURL.path),
              let data = try? Data(contentsOf: crashLogURL),
              let report = String(data: data, encoding: .utf8) else {
            return nil
        }
        try? FileManager.default.removeItem(at: crashLogURL)
        return report
    }

    /// Returns the last crash report without deleting it (for viewing).
    func peekLastCrashReport() -> String? {
        guard FileManager.default.fileExists(atPath: crashLogURL.path),
              let data = try? Data(contentsOf: crashLogURL),
              let report = String(data: data, encoding: .utf8) else {
            return nil
        }
        return report
    }

    /// Programmatically capture a snapshot of the current SystemConfig state.
    func captureEnvironment(from config: SystemConfig) {
        environmentSnapshot = [
            "accent": "\(config.accent)",
            "developerMode": "\(config.developerMode)",
            "sliderVibrationsEnabled": "\(config.sliderVibrationsEnabled)",
        ]
    }
}

// MARK: - Crash Report Viewer

/// A full-screen view that displays the last crash report with copy/share.
struct CrashReportView: View {
    let report: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Crash Report")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: report) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
