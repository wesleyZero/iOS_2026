//
//  SystemConfig.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

// MARK: - Custom Accent Color

struct CustomAccentColor: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var hue: Double        // 0…1
    var saturation: Double // 0…1
    var brightness: Double // 0…1

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// Resolution of a measurement field, representing the smallest increment the user's scale reads.
enum MeasurementResolution: Double, CaseIterable, Identifiable {
    case oneGram      = 1.0
    case tenthGram    = 0.1
    case hundredthGram = 0.01
    case thousandthGram = 0.001

    var id: Double { rawValue }

    var label: String { label(unit: "g") }

    func label(unit: String) -> String {
        switch self {
        case .oneGram:          return "1 \(unit)"
        case .tenthGram:        return "0.1 \(unit)"
        case .hundredthGram:    return "0.01 \(unit)"
        case .thousandthGram:   return "0.001 \(unit)"
        }
    }

    // Number of decimal places to display
    var decimalPlaces: Int {
        switch self {
        case .oneGram:          return 0
        case .tenthGram:        return 1
        case .hundredthGram:    return 2
        case .thousandthGram:   return 3
        }
    }
}

struct MoldSpec {
    var shape: GummyShape
    var count: Int
    var volume_ml: Double

    init(_ shape: GummyShape, _ count: Int, _ volume_ml: Double) {
        self.shape = shape
        self.count = count
        self.volume_ml = volume_ml
    }
}

@Observable
class SystemConfig {
    var circle   = MoldSpec(.circle,   35, 2.292)
    var star     = MoldSpec(.star,     28, 2.211)
    var heart    = MoldSpec(.heart,    36, 2.500)
    var cloud    = MoldSpec(.cloud,    36, 2.182)
    var oldBear  = MoldSpec(.oldBear,  24, 4.600)
    var newBear  = MoldSpec(.newBear,  35, 4.600)
    var mushroom = MoldSpec(.mushroom, 15, 3.000)

    static let defaultMoldSpecs: [GummyShape: MoldSpec] = [
        .circle:   MoldSpec(.circle,   35, 2.292),
        .star:     MoldSpec(.star,     28, 2.211),
        .heart:    MoldSpec(.heart,    36, 2.500),
        .cloud:    MoldSpec(.cloud,    36, 2.182),
        .oldBear:  MoldSpec(.oldBear,  24, 4.600),
        .newBear:  MoldSpec(.newBear,  35, 4.600),
        .mushroom: MoldSpec(.mushroom, 15, 3.000),
    ]

    func moldVolumeIsDefault(for shape: GummyShape) -> Bool {
        guard let def = Self.defaultMoldSpecs[shape] else { return true }
        return spec(for: shape).volume_ml == def.volume_ml
    }

    func moldCountIsDefault(for shape: GummyShape) -> Bool {
        guard let def = Self.defaultMoldSpecs[shape] else { return true }
        return spec(for: shape).count == def.count
    }

    func resetMoldVolume(for shape: GummyShape) {
        guard let def = Self.defaultMoldSpecs[shape] else { return }
        var s = spec(for: shape)
        s.volume_ml = def.volume_ml
        setSpec(s, for: shape)
    }

    func resetMoldCount(for shape: GummyShape) {
        guard let def = Self.defaultMoldSpecs[shape] else { return }
        var s = spec(for: shape)
        s.count = def.count
        setSpec(s, for: shape)
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "accentTheme"),
           let theme = AccentTheme(rawValue: saved) {
            self.accentTheme = theme
        }
        self.batchIDCounter = UserDefaults.standard.integer(forKey: "batchIDCounter")
        loadCustomAccentColors()
        loadSelectedCustomAccentID()
        loadContainerTareWeights()
        loadSavedDefaults()
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        }
        CMTheme.isDark = self.isDarkMode
    }

    // Sugar
    var glucoseToSugarMassRatio: Double = 1.000

    var glucoseToSugarVolumeRatio: Double {
        glucoseToSugarMassRatio * (densitySucrose / densityGlucoseSyrup)
    }

    // Additives
    var potassiumSorbatePercent: Double = 0.078
    var citricAcidPercent: Double = 0.638
    var additivesInputAsMassPercent: Bool = false

    // Ratios
    var waterToGelatinMassRatio: Double = 3.000
    var waterMassPercentInSugarMix: Double = 17.34

    // Transfer Liquids
    var lsdTransferWater_mL: Double = 1.000

    // Default ug / tab (used when resetting a batch)
    var defaultLsdUgPerTab: Double = 117.0

    // Derived ratio: sugar-to-water mass ratio from the water mass %
    var sugarToWaterMassRatio: Double {
        guard waterMassPercentInSugarMix > 0 else { return 0 }
        return (100.0 / waterMassPercentInSugarMix) - 1.0
    }

    // Computed: average sugar density (50/50 glucose syrup + granulated)
    var averageSugarDensity: Double {
        (densityGlucoseSyrup + densitySucrose) / 2.0
    }

    // Sugar mix density from equation (4): rho_mix = (1/(phi+1)) * rho_water + (phi/(phi+1)) * rho_sugar
    var sugarMixDensity: Double {
        let phi = sugarToWaterMassRatio
        return (1.0 / (phi + 1.0)) * densityWater
             + (phi / (phi + 1.0)) * averageSugarDensity
    }

    // Estimated density of the final gummy mixture (g/mL)
    var estimatedFinalMixDensity: Double = 1.308509

    // MARK: - Substance Densities (g/mL)
    var densityWater: Double = 0.9982
    var densityGlucoseSyrup: Double = 1.4500
    var densitySucrose: Double = 1.5872
    var densityGelatin: Double = 1.3500
    var densityCitricAcid: Double = 1.6650
    var densityPotassiumSorbate: Double = 1.3630
    var densityFlavorOil: Double = 1.0360
    var densityFoodColoring: Double = 1.2613
    var densityTerpenes: Double = 0.8411

    var additivesAreDefault: Bool {
        potassiumSorbatePercent == 0.078 && citricAcidPercent == 0.638
    }

    func resetAdditivesToDefault() {
        potassiumSorbatePercent = 0.078
        citricAcidPercent = 0.638
    }

    static let defaultDensities: [ReferenceWritableKeyPath<SystemConfig, Double>: Double] = [
        \.densityWater: 0.9982,
        \.densityGlucoseSyrup: 1.4500,
        \.densitySucrose: 1.5872,
        \.densityGelatin: 1.3500,
        \.densityCitricAcid: 1.6650,
        \.densityPotassiumSorbate: 1.3630,
        \.densityFlavorOil: 1.0360,
        \.densityFoodColoring: 1.2613,
        \.densityTerpenes: 0.8411,
        \.estimatedFinalMixDensity: 1.308509,
    ]

    func densityIsDefault(_ keyPath: ReferenceWritableKeyPath<SystemConfig, Double>) -> Bool {
        guard let defaultVal = Self.defaultDensities[keyPath] else { return true }
        return self[keyPath: keyPath] == defaultVal
    }

    func resetDensity(_ keyPath: ReferenceWritableKeyPath<SystemConfig, Double>) {
        if let defaultVal = Self.defaultDensities[keyPath] {
            self[keyPath: keyPath] = defaultVal
        }
    }

    func resetDensitiesToDefault() {
        for (keyPath, value) in Self.defaultDensities {
            self[keyPath: keyPath] = value
        }
    }

    // MARK: - Batch ID Counter
    // Stored as a base-26 index: 0 = "AA", 1 = "AB", ..., 25 = "AZ", 26 = "BA", etc.
    var batchIDCounter: Int = 0 {
        didSet { UserDefaults.standard.set(batchIDCounter, forKey: "batchIDCounter") }
    }

    /// Returns the current batch ID string and advances the counter.
    func nextBatchID() -> String {
        let id = batchIDString(for: batchIDCounter)
        batchIDCounter += 1
        return id
    }

    /// Peek at the next batch ID without advancing.
    func peekNextBatchID() -> String {
        batchIDString(for: batchIDCounter)
    }

    func batchIDString(for index: Int) -> String {
        let first = Character(UnicodeScalar(65 + (index / 26) % 26)!)
        let second = Character(UnicodeScalar(65 + index % 26)!)
        return String(first) + String(second)
    }

    /// Parse a two-letter batch ID back to its base-26 index, or nil if invalid.
    func batchIDIndex(for id: String) -> Int? {
        let upper = id.uppercased()
        guard upper.count == 2,
              let first = upper.first?.asciiValue,
              let second = upper.last?.asciiValue,
              first >= 65, first <= 90, second >= 65, second <= 90
        else { return nil }
        return Int(first - 65) * 26 + Int(second - 65)
    }

    /// Scan saved batches and set counter to one past the highest existing ID.
    func syncBatchIDCounter(from batches: [SavedBatch]) {
        var maxIndex = batchIDCounter - 1 // keep at least current
        for batch in batches {
            if let idx = batchIDIndex(for: batch.batchID) {
                maxIndex = max(maxIndex, idx)
            }
        }
        let newCounter = maxIndex + 1
        if newCounter > batchIDCounter {
            batchIDCounter = newCounter
        }
    }

    // MARK: - Container Tare Weights (A–Z)

    /// Saved tare weights for dehydration containers A through Z, persisted in UserDefaults.
    var containerTareWeights: [String: Double] = [:] {
        didSet { saveContainerTareWeights() }
    }

    private static let containerTareKey = "containerTareWeights"

    func containerTare(for label: String) -> Double {
        containerTareWeights[label] ?? 0
    }

    func setContainerTare(_ value: Double, for label: String) {
        containerTareWeights[label] = value
    }

    func resetContainerTare(for label: String) {
        containerTareWeights.removeValue(forKey: label)
    }

    func resetAllContainerTares() {
        containerTareWeights = [:]
    }

    var hasAnyContainerTare: Bool {
        containerTareWeights.values.contains { $0 != 0 }
    }

    private func saveContainerTareWeights() {
        if let data = try? JSONEncoder().encode(containerTareWeights) {
            UserDefaults.standard.set(data, forKey: Self.containerTareKey)
        }
    }

    private func loadContainerTareWeights() {
        if let data = UserDefaults.standard.data(forKey: Self.containerTareKey),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            containerTareWeights = dict
        }
    }

    // MARK: - Measurement Resolutions

    var resolutionBeakerEmpty: MeasurementResolution = .thousandthGram
    var resolutionBeakerPlusGelatin: MeasurementResolution = .thousandthGram
    var resolutionBeakerPlusSugar: MeasurementResolution = .thousandthGram
    var resolutionBeakerPlusActive: MeasurementResolution = .thousandthGram
    var resolutionBeakerResidue: MeasurementResolution = .thousandthGram
    var resolutionSyringeEmpty: MeasurementResolution = .thousandthGram
    var resolutionSyringeWithMix: MeasurementResolution = .thousandthGram
    var resolutionSyringeResidue: MeasurementResolution = .thousandthGram
    var resolutionMoldsFilled: MeasurementResolution = .tenthGram

    // MARK: - Accent Theme

    var accentTheme: AccentTheme = .teal {
        didSet { UserDefaults.standard.set(accentTheme.rawValue, forKey: "accentTheme") }
    }

    /// The ID of a selected custom accent color, or nil if using a preset theme.
    var selectedCustomAccentID: UUID? = nil {
        didSet {
            if let id = selectedCustomAccentID {
                UserDefaults.standard.set(id.uuidString, forKey: "selectedCustomAccentID")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedCustomAccentID")
            }
        }
    }

    /// Dynamic accent color resolved from the user's selected theme or custom color.
    var accent: Color {
        if let id = selectedCustomAccentID,
           let custom = customAccentColors.first(where: { $0.id == id }) {
            return custom.color
        }
        return accentTheme.color
    }

    /// The display name for the current accent selection.
    var accentDisplayName: String {
        if let id = selectedCustomAccentID,
           let custom = customAccentColors.first(where: { $0.id == id }) {
            return custom.name
        }
        return accentTheme.rawValue
    }

    // MARK: - Custom Accent Colors

    var customAccentColors: [CustomAccentColor] = [] {
        didSet { saveCustomAccentColors() }
    }

    func addCustomAccentColor(_ color: CustomAccentColor) {
        customAccentColors.append(color)
    }

    func deleteCustomAccentColor(at offsets: IndexSet) {
        let idsToDelete = offsets.map { customAccentColors[$0].id }
        // If the currently selected custom color is being deleted, revert to preset
        if let selectedID = selectedCustomAccentID, idsToDelete.contains(selectedID) {
            selectedCustomAccentID = nil
        }
        customAccentColors.remove(atOffsets: offsets)
    }

    func deleteCustomAccentColor(id: UUID) {
        if selectedCustomAccentID == id {
            selectedCustomAccentID = nil
        }
        customAccentColors.removeAll { $0.id == id }
    }

    private func saveCustomAccentColors() {
        if let data = try? JSONEncoder().encode(customAccentColors) {
            UserDefaults.standard.set(data, forKey: "customAccentColors")
        }
    }

    private func loadCustomAccentColors() {
        if let data = UserDefaults.standard.data(forKey: "customAccentColors"),
           let colors = try? JSONDecoder().decode([CustomAccentColor].self, from: data) {
            customAccentColors = colors
        }
    }

    private func loadSelectedCustomAccentID() {
        if let str = UserDefaults.standard.string(forKey: "selectedCustomAccentID"),
           let uuid = UUID(uuidString: str) {
            selectedCustomAccentID = uuid
        }
    }

    // MARK: - Appearance Mode
    var isDarkMode: Bool = true {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            CMTheme.isDark = isDarkMode
        }
    }

    var preferredColorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }

    // MARK: - Haptic Feedback
    var sliderVibrationsEnabled: Bool = true

    // MARK: - Developer Mode

    var developerMode: Bool = false
    var expandDetailSectionsByDefault: Bool = false
    var syntheticDataSet1Enabled: Bool = false
    var syntheticMeasurementsEnabled: Bool = false

    /// Applies "Dataset 1" overrides when developer mode is toggled on.
    func applyDevMode(to viewModel: BatchConfigViewModel) {
        // Override new bear molds to 77
        newBear.count = 77

        // Pick 4 random flavor oils
        let randomOils = Array(FlavorOil.allCases.shuffled().prefix(4))
        // Pick 4 random terpenes
        let randomTerps = Array(TerpeneFlavor.allCases.shuffled().prefix(4))
        // Pick 2 random colors
        let randomColors = Array(GummyColor.allCases.shuffled().prefix(2))

        // Clear existing selections
        viewModel.selectedFlavors = [:]
        viewModel.selectedColors = [:]
        viewModel.oilsLocked = false
        viewModel.terpenesLocked = false
        viewModel.flavorCompositionLocked = false
        viewModel.colorsLocked = false
        viewModel.colorCompositionLocked = false

        // Add flavor oils (equal distribution)
        for oil in randomOils {
            viewModel.selectedFlavors[.oil(oil)] = 25.0
        }
        // Add terpenes (equal distribution)
        for terp in randomTerps {
            viewModel.selectedFlavors[.terpene(terp)] = 25.0
        }
        // Add colors (equal distribution)
        for color in randomColors {
            viewModel.selectedColors[color] = 50.0
        }

        // Lock selections
        viewModel.oilsLocked = true
        viewModel.terpenesLocked = true
        viewModel.flavorCompositionLocked = true
        viewModel.colorsLocked = true
        viewModel.colorCompositionLocked = true

        // Auto-calculate the batch
        viewModel.batchCalculated = true
    }

    /// Reverts developer mode overrides.
    func revertDevMode(to viewModel: BatchConfigViewModel) {
        // Restore default new bear molds
        newBear.count = 35

        // Clear the auto-selected flavors and colors
        viewModel.selectedFlavors = [:]
        viewModel.selectedColors = [:]
        viewModel.oilsLocked = false
        viewModel.terpenesLocked = false
        viewModel.flavorCompositionLocked = false
        viewModel.colorsLocked = false
        viewModel.colorCompositionLocked = false
    }

    /// Fills all measurement fields with realistic synthetic data.
    func applySyntheticMeasurements(to viewModel: BatchConfigViewModel) {
        // Beaker tare weight (typical 250 mL glass beaker)
        viewModel.weightBeakerEmpty = 114.823

        // Gelatin mix added: ~21 g gelatin + ~63 g water = ~84 g total
        viewModel.weightBeakerPlusGelatin = 199.041

        // Sugar mix added: ~180 g sugar mix
        viewModel.weightBeakerPlusSugar = 379.187

        // Activation mix (active + small transfer water): ~3.4 g
        viewModel.weightBeakerPlusActive = 382.619

        // Beaker after transfer to syringe — small residue left behind
        viewModel.weightBeakerResidue = 117.342

        // Syringe tare
        viewModel.weightSyringeEmpty = 47.215

        // Syringe loaded with gummy mix (~260 g mix)
        viewModel.weightSyringeWithMix = 308.801

        // Volume of gummy mix in syringe (~200 mL)
        viewModel.volumeSyringeGummyMix = 198.4

        // Syringe after filling trays — small residue
        viewModel.weightSyringeResidue = 48.934

        // Tray clean weight
        viewModel.weightTrayClean = 83.512

        // Tray with residue after filling
        viewModel.weightTrayPlusResidue = 84.205

        // Molds filled
        viewModel.weightMoldsFilled = 74.0

        // Extra gummy mix poured off (surplus)
        viewModel.extraGummyMix_g = 1.847

        // Calibration: Sugar mix density syringe
        viewModel.densitySyringeCleanSugar = 47.218
        viewModel.densitySyringePlusSugarMass = 97.643
        viewModel.densitySyringePlusSugarVol = 38.2

        // Calibration: Gelatin mix density syringe
        viewModel.densitySyringeCleanGelatin = 47.221
        viewModel.densitySyringePlusGelatinMass = 80.156
        viewModel.densitySyringePlusGelatinVol = 24.8

        // Calibration: Activation mix density syringe
        viewModel.densitySyringeCleanActive = 47.219
        viewModel.densitySyringePlusActiveMass = 89.374
        viewModel.densitySyringePlusActiveVol = 32.1
    }

    /// Clears all synthetic measurement data from the view model.
    func clearSyntheticMeasurements(from viewModel: BatchConfigViewModel) {
        viewModel.weightBeakerEmpty = nil
        viewModel.weightBeakerPlusGelatin = nil
        viewModel.weightBeakerPlusSugar = nil
        viewModel.weightBeakerPlusActive = nil
        viewModel.weightBeakerResidue = nil
        viewModel.weightSyringeEmpty = nil
        viewModel.weightSyringeWithMix = nil
        viewModel.volumeSyringeGummyMix = nil
        viewModel.weightSyringeResidue = nil
        viewModel.weightTrayClean = nil
        viewModel.weightTrayPlusResidue = nil
        viewModel.weightMoldsFilled = nil
        viewModel.extraGummyMix_g = nil
        viewModel.densitySyringeCleanSugar = nil
        viewModel.densitySyringePlusSugarMass = nil
        viewModel.densitySyringePlusSugarVol = nil
        viewModel.densitySyringeCleanGelatin = nil
        viewModel.densitySyringePlusGelatinMass = nil
        viewModel.densitySyringePlusGelatinVol = nil
        viewModel.densitySyringeCleanActive = nil
        viewModel.densitySyringePlusActiveMass = nil
        viewModel.densitySyringePlusActiveVol = nil
    }

    func setSpec(_ spec: MoldSpec, for shape: GummyShape) {
        switch shape {
        case .circle:   circle = spec
        case .star:     star = spec
        case .heart:    heart = spec
        case .cloud:    cloud = spec
        case .oldBear:  oldBear = spec
        case .newBear:  newBear = spec
        case .mushroom: mushroom = spec
        }
    }

    func spec(for shape: GummyShape) -> MoldSpec {
        switch shape {
        case .circle:   return circle
        case .star:     return star
        case .heart:    return heart
        case .cloud:    return cloud
        case .oldBear:  return oldBear
        case .newBear:  return newBear
        case .mushroom: return mushroom
        }
    }

    // MARK: - Settings Change Detection

    var hasAnySettingChanged: Bool {
        // Mold specs
        for shape in GummyShape.allCases {
            if !moldVolumeIsDefault(for: shape) || !moldCountIsDefault(for: shape) { return true }
        }
        // Sugar ratio
        if glucoseToSugarMassRatio != 1.000 { return true }
        // Ratios
        if waterToGelatinMassRatio != 3.000 { return true }
        if waterMassPercentInSugarMix != 17.34 { return true }
        // Additives
        if potassiumSorbatePercent != 0.078 { return true }
        if citricAcidPercent != 0.638 { return true }
        // Densities
        for (keyPath, defaultVal) in Self.defaultDensities {
            if self[keyPath: keyPath] != defaultVal { return true }
        }
        return false
    }

    /// Compares current settings (Tier 3) against Tier 1 factory defaults.
    /// Drives the "Factory Reset" button.
    var hasSettingsChangedFromFactory: Bool {
        !settingsMatch(factorySettingsJSON())
    }

    /// Compares current settings (Tier 3) against the active system defaults
    /// (Tier 2 if saved, otherwise Tier 1 factory). Drives the "Assign current
    /// settings as new defaults" button.
    var hasSettingsChangedFromDefaults: Bool {
        let referenceJSON: [String: Any]
        if let jsonString = UserDefaults.standard.string(forKey: "customDefaultSettings"),
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            referenceJSON = json
        } else {
            referenceJSON = factorySettingsJSON()
        }
        return !settingsMatch(referenceJSON)
    }

    /// Returns a JSON dictionary representing all Tier 1 factory defaults.
    private func factorySettingsJSON() -> [String: Any] {
        var molds: [[String: Any]] = []
        for shape in GummyShape.allCases {
            if let def = Self.defaultMoldSpecs[shape] {
                molds.append(["shape": shape.rawValue, "count": def.count, "volume_ml": def.volume_ml])
            }
        }
        return [
            "moldSpecs": molds,
            "glucoseToSugarMassRatio": 1.000,
            "waterToGelatinMassRatio": 3.000,
            "waterMassPercentInSugarMix": 17.34,
            "potassiumSorbatePercent": 0.078,
            "citricAcidPercent": 0.638,
            "estimatedFinalMixDensity": 1.308509,
            "densityWater": 0.9982,
            "densityGlucoseSyrup": 1.4500,
            "densitySucrose": 1.5872,
            "densityGelatin": 1.3500,
            "densityCitricAcid": 1.6650,
            "densityPotassiumSorbate": 1.3630,
            "densityFlavorOil": 1.0360,
            "densityFoodColoring": 1.2613,
            "densityTerpenes": 0.8411,
            "lsdTransferWater_mL": 1.000,
            "defaultLsdUgPerTab": 117.0,
            "additivesInputAsMassPercent": false,
            "sliderVibrationsEnabled": true,
            "isDarkMode": true,
            "resolutionBeakerEmpty": MeasurementResolution.thousandthGram.rawValue,
            "resolutionBeakerPlusGelatin": MeasurementResolution.thousandthGram.rawValue,
            "resolutionBeakerPlusSugar": MeasurementResolution.thousandthGram.rawValue,
            "resolutionBeakerPlusActive": MeasurementResolution.thousandthGram.rawValue,
            "resolutionBeakerResidue": MeasurementResolution.thousandthGram.rawValue,
            "resolutionSyringeEmpty": MeasurementResolution.thousandthGram.rawValue,
            "resolutionSyringeWithMix": MeasurementResolution.thousandthGram.rawValue,
            "resolutionSyringeResidue": MeasurementResolution.thousandthGram.rawValue,
            "resolutionMoldsFilled": MeasurementResolution.tenthGram.rawValue,
        ] as [String: Any]
    }

    /// Compares the current in-memory settings against a reference JSON dictionary.
    private func settingsMatch(_ ref: [String: Any]) -> Bool {
        let current = settingsToJSON()

        // Compare Double values
        let doubleKeys = [
            "glucoseToSugarMassRatio", "waterToGelatinMassRatio", "waterMassPercentInSugarMix",
            "potassiumSorbatePercent", "citricAcidPercent",
            "estimatedFinalMixDensity", "densityWater", "densityGlucoseSyrup", "densitySucrose",
            "densityGelatin", "densityCitricAcid", "densityPotassiumSorbate",
            "densityFlavorOil", "densityFoodColoring", "densityTerpenes",
            "lsdTransferWater_mL", "defaultLsdUgPerTab",
            "resolutionBeakerEmpty", "resolutionBeakerPlusGelatin",
            "resolutionBeakerPlusSugar", "resolutionBeakerPlusActive",
            "resolutionBeakerResidue", "resolutionSyringeEmpty",
            "resolutionSyringeWithMix", "resolutionSyringeResidue",
            "resolutionMoldsFilled",
        ]
        for key in doubleKeys {
            let curVal = current[key] as? Double ?? 0
            let refVal = ref[key] as? Double ?? 0
            if curVal != refVal { return false }
        }

        // Compare Bool values
        let boolKeys = ["additivesInputAsMassPercent", "sliderVibrationsEnabled", "isDarkMode"]
        for key in boolKeys {
            let curVal = current[key] as? Bool ?? false
            let refVal = ref[key] as? Bool ?? false
            if curVal != refVal { return false }
        }

        // Compare mold specs
        if let curMolds = current["moldSpecs"] as? [[String: Any]],
           let refMolds = ref["moldSpecs"] as? [[String: Any]] {
            if curMolds.count != refMolds.count { return false }
            for (cm, rm) in zip(curMolds, refMolds) {
                if (cm["shape"] as? String) != (rm["shape"] as? String) { return false }
                if (cm["count"] as? Int) != (rm["count"] as? Int) { return false }
                if (cm["volume_ml"] as? Double) != (rm["volume_ml"] as? Double) { return false }
            }
        } else {
            return false
        }

        return true
    }

    // MARK: - Settings JSON Export / Import

    func settingsToJSON() -> [String: Any] {
        var molds: [[String: Any]] = []
        for shape in GummyShape.allCases {
            let s = spec(for: shape)
            molds.append(["shape": shape.rawValue, "count": s.count, "volume_ml": s.volume_ml])
        }
        return [
            "moldSpecs": molds,
            "glucoseToSugarMassRatio": glucoseToSugarMassRatio,
            "waterToGelatinMassRatio": waterToGelatinMassRatio,
            "waterMassPercentInSugarMix": waterMassPercentInSugarMix,
            "potassiumSorbatePercent": potassiumSorbatePercent,
            "citricAcidPercent": citricAcidPercent,
            "estimatedFinalMixDensity": estimatedFinalMixDensity,
            "densityWater": densityWater,
            "densityGlucoseSyrup": densityGlucoseSyrup,
            "densitySucrose": densitySucrose,
            "densityGelatin": densityGelatin,
            "densityCitricAcid": densityCitricAcid,
            "densityPotassiumSorbate": densityPotassiumSorbate,
            "densityFlavorOil": densityFlavorOil,
            "densityFoodColoring": densityFoodColoring,
            "densityTerpenes": densityTerpenes,
            "lsdTransferWater_mL": lsdTransferWater_mL,
            "defaultLsdUgPerTab": defaultLsdUgPerTab,
            "additivesInputAsMassPercent": additivesInputAsMassPercent,
            "sliderVibrationsEnabled": sliderVibrationsEnabled,
            "isDarkMode": isDarkMode,
            "resolutionBeakerEmpty": resolutionBeakerEmpty.rawValue,
            "resolutionBeakerPlusGelatin": resolutionBeakerPlusGelatin.rawValue,
            "resolutionBeakerPlusSugar": resolutionBeakerPlusSugar.rawValue,
            "resolutionBeakerPlusActive": resolutionBeakerPlusActive.rawValue,
            "resolutionBeakerResidue": resolutionBeakerResidue.rawValue,
            "resolutionSyringeEmpty": resolutionSyringeEmpty.rawValue,
            "resolutionSyringeWithMix": resolutionSyringeWithMix.rawValue,
            "resolutionSyringeResidue": resolutionSyringeResidue.rawValue,
            "resolutionMoldsFilled": resolutionMoldsFilled.rawValue,
        ] as [String: Any]
    }

    func settingsJSONString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: settingsToJSON(), options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func loadSettings(from json: [String: Any]) {
        if let molds = json["moldSpecs"] as? [[String: Any]] {
            for m in molds {
                guard let shapeName = m["shape"] as? String,
                      let shape = GummyShape.allCases.first(where: { $0.rawValue == shapeName }) else { continue }
                var s = spec(for: shape)
                if let count = m["count"] as? Int { s.count = count }
                if let vol = m["volume_ml"] as? Double { s.volume_ml = vol }
                setSpec(s, for: shape)
            }
        }
        if let v = json["glucoseToSugarMassRatio"] as? Double { glucoseToSugarMassRatio = v }
        if let v = json["waterToGelatinMassRatio"] as? Double { waterToGelatinMassRatio = v }
        if let v = json["waterMassPercentInSugarMix"] as? Double { waterMassPercentInSugarMix = v }
        if let v = json["potassiumSorbatePercent"] as? Double { potassiumSorbatePercent = v }
        if let v = json["citricAcidPercent"] as? Double { citricAcidPercent = v }
        if let v = json["estimatedFinalMixDensity"] as? Double { estimatedFinalMixDensity = v }
        if let v = json["densityWater"] as? Double { densityWater = v }
        if let v = json["densityGlucoseSyrup"] as? Double { densityGlucoseSyrup = v }
        if let v = json["densitySucrose"] as? Double { densitySucrose = v }
        if let v = json["densityGelatin"] as? Double { densityGelatin = v }
        if let v = json["densityCitricAcid"] as? Double { densityCitricAcid = v }
        if let v = json["densityPotassiumSorbate"] as? Double { densityPotassiumSorbate = v }
        if let v = json["densityFlavorOil"] as? Double { densityFlavorOil = v }
        if let v = json["densityFoodColoring"] as? Double { densityFoodColoring = v }
        if let v = json["densityTerpenes"] as? Double { densityTerpenes = v }
        if let v = json["lsdTransferWater_mL"] as? Double { lsdTransferWater_mL = v }
        if let v = json["defaultLsdUgPerTab"] as? Double { defaultLsdUgPerTab = v }
        if let v = json["additivesInputAsMassPercent"] as? Bool { additivesInputAsMassPercent = v }
        if let v = json["sliderVibrationsEnabled"] as? Bool { sliderVibrationsEnabled = v }
        if let v = json["isDarkMode"] as? Bool { isDarkMode = v }
        if let v = json["resolutionBeakerEmpty"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionBeakerEmpty = r }
        if let v = json["resolutionBeakerPlusGelatin"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionBeakerPlusGelatin = r }
        if let v = json["resolutionBeakerPlusSugar"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionBeakerPlusSugar = r }
        if let v = json["resolutionBeakerPlusActive"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionBeakerPlusActive = r }
        if let v = json["resolutionBeakerResidue"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionBeakerResidue = r }
        if let v = json["resolutionSyringeEmpty"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionSyringeEmpty = r }
        if let v = json["resolutionSyringeWithMix"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionSyringeWithMix = r }
        if let v = json["resolutionSyringeResidue"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionSyringeResidue = r }
        if let v = json["resolutionMoldsFilled"] as? Double,
           let r = MeasurementResolution(rawValue: v) { resolutionMoldsFilled = r }
    }

    func assignCurrentAsDefaults() {
        // Persist current settings to UserDefaults as the new "defaults"
        if let jsonString = settingsJSONString() {
            UserDefaults.standard.set(jsonString, forKey: "customDefaultSettings")
        }
    }

    /// Resets every setting back to its original hardcoded factory default.
    func factoryReset() {
        // Mold specs
        for shape in GummyShape.allCases {
            if let def = Self.defaultMoldSpecs[shape] {
                setSpec(def, for: shape)
            }
        }

        // Sugar ratio
        glucoseToSugarMassRatio = 1.000

        // Ratios
        waterToGelatinMassRatio = 3.000
        waterMassPercentInSugarMix = 17.34

        // Transfer liquids
        lsdTransferWater_mL = 1.000

        // Default µg / tab
        defaultLsdUgPerTab = 117.0

        // Additives
        potassiumSorbatePercent = 0.078
        citricAcidPercent = 0.638
        additivesInputAsMassPercent = false

        // Densities
        resetDensitiesToDefault()

        // Measurement resolutions
        resolutionBeakerEmpty = .thousandthGram
        resolutionBeakerPlusGelatin = .thousandthGram
        resolutionBeakerPlusSugar = .thousandthGram
        resolutionBeakerPlusActive = .thousandthGram
        resolutionBeakerResidue = .thousandthGram
        resolutionSyringeEmpty = .thousandthGram
        resolutionSyringeWithMix = .thousandthGram
        resolutionSyringeResidue = .thousandthGram
        resolutionMoldsFilled = .tenthGram

        // Container tare weights
        resetAllContainerTares()

        // Haptics
        sliderVibrationsEnabled = true

        // Appearance
        isDarkMode = true
    }

    var hasSavedDefaults: Bool {
        UserDefaults.standard.string(forKey: "customDefaultSettings") != nil
    }

    func loadSavedDefaults() {
        guard let jsonString = UserDefaults.standard.string(forKey: "customDefaultSettings"),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        loadSettings(from: json)
    }
}
