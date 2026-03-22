//
//  BatchRequest.swift
//  CandyMan
//
//  SwiftData model for customer batch requests. A request captures the key
//  parameters from a pasted batch configuration along with the requester's
//  name, so it can be reviewed and fulfilled later from the Templates &
//  Requests screen.
//

import Foundation
import SwiftData

@Model
class BatchRequest {
    var requesterName: String
    var createdDate: Date

    // Batch summary fields (from pasted SavedBatchDTO)
    var shape: String
    var trayCount: Int
    var wellCount: Int
    var activeName: String
    var activeConcentration: Double
    var activeUnit: String
    var gelatinPercent: Double
    var flavorOilVolumePercent: Double
    var terpenePPM: Double
    var colorVolumePercent: Double
    var overageFactor: Double

    // Flavor & color summaries (stored as comma-separated display strings)
    var flavorSummary: String
    var colorSummary: String

    // The full JSON blob so the user can re-export or inspect later
    var rawJSON: String

    var isFulfilled: Bool = false

    init(
        requesterName: String,
        createdDate: Date = .now,
        shape: String,
        trayCount: Int,
        wellCount: Int,
        activeName: String,
        activeConcentration: Double,
        activeUnit: String,
        gelatinPercent: Double,
        flavorOilVolumePercent: Double,
        terpenePPM: Double,
        colorVolumePercent: Double,
        overageFactor: Double,
        flavorSummary: String,
        colorSummary: String,
        rawJSON: String
    ) {
        self.requesterName = requesterName
        self.createdDate = createdDate
        self.shape = shape
        self.trayCount = trayCount
        self.wellCount = wellCount
        self.activeName = activeName
        self.activeConcentration = activeConcentration
        self.activeUnit = activeUnit
        self.gelatinPercent = gelatinPercent
        self.flavorOilVolumePercent = flavorOilVolumePercent
        self.terpenePPM = terpenePPM
        self.colorVolumePercent = colorVolumePercent
        self.overageFactor = overageFactor
        self.flavorSummary = flavorSummary
        self.colorSummary = colorSummary
        self.rawJSON = rawJSON
    }
}

// MARK: - Factory from SavedBatchDTO

extension BatchRequest {
    /// Creates a BatchRequest from a single SavedBatchDTO and the raw JSON string.
    static func from(dto: SavedBatchDTO, requesterName: String, rawJSON: String) -> BatchRequest {
        let flavorNames = dto.flavors.sorted { $0.percent > $1.percent }.map { $0.name }
        let colorNames = dto.colors.sorted { $0.percent > $1.percent }.map { $0.name }

        return BatchRequest(
            requesterName: requesterName,
            shape: dto.shape,
            trayCount: dto.trayCount,
            wellCount: dto.wellCount,
            activeName: dto.activeName,
            activeConcentration: dto.activeConcentration,
            activeUnit: dto.activeUnit,
            gelatinPercent: dto.gelatinPercent,
            flavorOilVolumePercent: dto.flavorOilVolumePercent,
            terpenePPM: dto.terpenePPM,
            colorVolumePercent: dto.colorVolumePercent,
            overageFactor: dto.overageFactor ?? 1.03,
            flavorSummary: flavorNames.joined(separator: ", "),
            colorSummary: colorNames.joined(separator: ", "),
            rawJSON: rawJSON
        )
    }

    /// Creates a BatchRequest from the lightweight config JSON produced by
    /// InputSummaryView's "Copy" button.
    static func from(config: BatchConfigDTO, requesterName: String, rawJSON: String) -> BatchRequest {
        // Build flavor summary from terpene + oil blend keys
        var flavorNames: [String] = []
        if let blend = config.terpenes?.blend {
            flavorNames.append(contentsOf: blend.keys.sorted())
        }
        if let blend = config.flavorOils?.blend {
            flavorNames.append(contentsOf: blend.keys.sorted())
        }
        let colorNames = config.colors?.blend?.keys.sorted() ?? []

        return BatchRequest(
            requesterName: requesterName,
            shape: config.shape,
            trayCount: config.trays,
            wellCount: config.gummies,
            activeName: config.active,
            activeConcentration: config.concentration,
            activeUnit: config.concentrationUnit,
            gelatinPercent: config.gelatinPercent,
            flavorOilVolumePercent: config.flavorOils?.volumePercent ?? 0,
            terpenePPM: config.terpenes?.ppm ?? 0,
            colorVolumePercent: config.colors?.volumePercent ?? 0,
            overageFactor: 1.03,
            flavorSummary: flavorNames.joined(separator: ", "),
            colorSummary: colorNames.joined(separator: ", "),
            rawJSON: rawJSON
        )
    }
}

// MARK: - Lightweight Batch Config DTO

/// Matches the JSON format produced by InputSummaryView's copyConfigJSON().
struct BatchConfigDTO: Codable {
    var shape: String
    var trays: Int
    var gummies: Int
    var active: String
    var concentration: Double
    var concentrationUnit: String
    var gelatinPercent: Double
    var terpenes: TerpeneBlendDTO?
    var flavorOils: FlavorOilBlendDTO?
    var colors: ColorBlendDTO?

    struct TerpeneBlendDTO: Codable {
        var ppm: Double
        var blend: [String: Double]?
    }

    struct FlavorOilBlendDTO: Codable {
        var volumePercent: Double
        var blend: [String: Double]?
    }

    struct ColorBlendDTO: Codable {
        var volumePercent: Double
        var blend: [String: Double]?
    }
}
