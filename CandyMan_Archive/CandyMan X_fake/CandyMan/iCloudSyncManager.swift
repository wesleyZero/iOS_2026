//
//  iCloudSyncManager.swift
//  CandyMan
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - iCloud Sync Manager
//
// Uses NSUbiquitousKeyValueStore — requires only the key-value storage entitlement,
// which Xcode adds automatically when you enable iCloud → Key-value storage in
// Signing & Capabilities. No iCloud Drive or container identifiers needed.
//
// To enable: Xcode → Target → Signing & Capabilities → + Capability → iCloud
//            then check "Key-value storage". That's it.

@Observable
final class iCloudSyncManager {

    // MARK: - State
    private(set) var isSignedIn: Bool = false
    private(set) var manifest: BackupManifest? = nil
    private(set) var isBackingUp: Bool = false
    private(set) var isRestoring: Bool = false
    var lastError: String? = nil

    // MARK: - KVStore Keys
    private let batchesKey  = "candyman_batches_v1"
    private let manifestKey = "candyman_manifest_v1"

    // MARK: - Init
    init() {
        refreshSignInState()
        loadManifestFromStore()
        NSUbiquitousKeyValueStore.default.synchronize()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(kvStoreChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }

    // MARK: - Sign-In Detection
    // ubiquityIdentityToken reflects whether an Apple ID is signed into iCloud
    // on this device. KVStore only needs this — no container entitlement required.

    func refreshSignInState() {
        isSignedIn = FileManager.default.ubiquityIdentityToken != nil
        if !isSignedIn { manifest = nil }
    }

    static func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    // MARK: - Backup

    @MainActor
    func backup(batches: [SavedBatch]) async throws {
        isBackingUp = true
        defer { isBackingUp = false }

        let dtos = batches.map { $0.toDTO() }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let batchData: Data
        do {
            batchData = try encoder.encode(dtos)
        } catch {
            throw SyncError.encodingFailed(underlying: error.localizedDescription)
        }

        guard batchData.count < 950_000 else {
            throw SyncError.payloadTooLarge(sizeKB: batchData.count / 1024)
        }

        let newManifest = BackupManifest(
            backupDate: Date(),
            batchCount: dtos.count,
            appVersion: Bundle.main.shortVersionString,
            sizeBytes: batchData.count
        )
        let manifestData = try encoder.encode(newManifest)

        let store = NSUbiquitousKeyValueStore.default
        store.set(batchData, forKey: batchesKey)
        store.set(manifestData, forKey: manifestKey)
        let synced = store.synchronize()

        // Verify the write actually landed in the store before declaring success
        guard store.data(forKey: batchesKey) != nil else {
            throw SyncError.writeFailed("Batch data was not retained by iCloud KVStore after synchronize() returned \(synced). Check that the iCloud Key-value storage capability is enabled in Signing & Capabilities.")
        }

        self.manifest = newManifest
    }

    // MARK: - Restore

    @MainActor
    func restore(into context: ModelContext, allBatches: [SavedBatch], systemConfig: SystemConfig) async throws -> Int {
        isRestoring = true
        defer { isRestoring = false }

        NSUbiquitousKeyValueStore.default.synchronize()

        // Try current key, then fall back to legacy dot-notation key from earlier app versions
        let legacyBatchesKey = "candyman.batches.v1"
        let batchData = NSUbiquitousKeyValueStore.default.data(forKey: batchesKey)
            ?? NSUbiquitousKeyValueStore.default.data(forKey: legacyBatchesKey)
        guard let batchData else {
            throw SyncError.noBackupFound
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dtos: [SavedBatchDTO]
        do {
            dtos = try decoder.decode([SavedBatchDTO].self, from: batchData)
        } catch {
            throw SyncError.decodingFailed(underlying: error.localizedDescription)
        }

        // Additive only — skip batchIDs already present locally
        let existingIDs = Set(allBatches.compactMap { $0.batchID.isEmpty ? nil : $0.batchID })
        var importedCount = 0
        for dto in dtos {
            if dto.batchID.isEmpty || !existingIDs.contains(dto.batchID) {
                SavedBatch.from(dto: dto, context: context)
                importedCount += 1
            }
        }
        if importedCount > 0 {
            try context.save()
            let updated = (try? context.fetch(FetchDescriptor<SavedBatch>())) ?? []
            systemConfig.syncBatchIDCounter(from: updated)
        }
        return importedCount
    }

    // MARK: - KVStore change notification (from another device)

    @objc private func kvStoreChanged(_ notification: Notification) {
        loadManifestFromStore()
        refreshSignInState()
    }

    private func loadManifestFromStore() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: manifestKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let m = try? decoder.decode(BackupManifest.self, from: data) {
            manifest = m
        }
    }

    // MARK: - Errors

    enum SyncError: LocalizedError {
        case encodingFailed(underlying: String)
        case payloadTooLarge(sizeKB: Int)
        case noBackupFound
        case decodingFailed(underlying: String)
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .encodingFailed(let msg):
                return "Could not encode batch data: \(msg)"
            case .payloadTooLarge(let kb):
                return "Backup is too large (\(kb) KB). iCloud key-value storage has a 1 MB limit. Try deleting trashed batches first."
            case .noBackupFound:
                return "No backup found in iCloud. Back up from this or another device first."
            case .decodingFailed(let msg):
                return "Backup data could not be read: \(msg)"
            case .writeFailed(let msg):
                return "iCloud write failed: \(msg)"
            }
        }
    }
}

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
