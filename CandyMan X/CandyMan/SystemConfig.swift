//
//  SystemConfig.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//
//  Global, app-wide configuration for mold geometry, substance densities,
//  measurement resolutions, appearance, and user preferences.
//
//  Tier system for defaults:
//    Tier 1 — Factory hardcoded (see `factorySettingsJSON()`)
//    Tier 2 — User-saved defaults (persisted via "customDefaultSettings" in UserDefaults)
//    Tier 3 — Live in-memory settings (the properties on this class)
//

import Foundation
import SwiftUI

// MARK: - Numeric Input Mode

/// User preference for numeric input method.
enum NumericInputMode: String, CaseIterable {
    case auto     = "auto"     // iPad = custom keypad, iPhone = system keyboard
    case keypad   = "keypad"   // Always use custom keypad
    case keyboard = "keyboard" // Always use system keyboard
}

// MARK: - Custom Accent Color

/// A user-defined HSB accent color, persisted via JSON in UserDefaults.
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

// MARK: - Measurement Resolution

/// Resolution of a measurement field — the smallest increment the user's scale reads.
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

    /// Number of decimal places to display for this resolution.
    var decimalPlaces: Int {
        switch self {
        case .oneGram:          return 0
        case .tenthGram:        return 1
        case .hundredthGram:    return 2
        case .thousandthGram:   return 3
        }
    }
}

// MARK: - Mold Spec

/// Geometry of a single mold tray: shape, cavity count, and per-cavity volume.
struct MoldSpec {
    var shape: GummyShape
    var count: Int        // cavities per tray
    var volumeML: Double  // mL per cavity

    init(_ shape: GummyShape, _ count: Int, _ volumeML: Double) {
        self.shape = shape
        self.count = count
        self.volumeML = volumeML
    }
}

// MARK: - Scale Spec

/// A laboratory scale with a name, resolution (smallest readable increment), and max capacity.
struct ScaleSpec: Identifiable, Equatable {
    let id: String   // e.g. "A", "B", "C"
    var name: String  // display label
    var resolution: Double // grams (e.g. 0.001)
    var maxCapacity: Double // grams (e.g. 100)

    /// Formatted resolution label (e.g. "0.001 g").
    var resolutionLabel: String {
        if resolution >= 1 { return String(format: "%.0f g", resolution) }
        if resolution >= 0.1 { return String(format: "%.1f g", resolution) }
        if resolution >= 0.01 { return String(format: "%.2f g", resolution) }
        return String(format: "%.3f g", resolution)
    }

    /// Formatted capacity label (e.g. "100 g").
    var capacityLabel: String {
        if maxCapacity >= 1000 { return String(format: "%.0f g", maxCapacity) }
        return String(format: "%.0f g", maxCapacity)
    }

    static let factoryDefaults: [ScaleSpec] = [
        ScaleSpec(id: "A", name: "Scale A", resolution: 0.001, maxCapacity: 100),
        ScaleSpec(id: "B", name: "Scale B", resolution: 0.01,  maxCapacity: 500),
        ScaleSpec(id: "C", name: "Scale C", resolution: 0.1,   maxCapacity: 5000),
    ]
}

// MARK: - System Config

/// Global configuration for mold specifications, substance densities, and user preferences.
///
/// Injected via `@Environment(SystemConfig.self)` into the view hierarchy.
/// Persists user-modified defaults to UserDefaults and supports factory reset.
@Observable
final class SystemConfig {
    var circle   = MoldSpec(.circle,   35, 2.292)
    var star     = MoldSpec(.star,     28, 2.211)
    var heart    = MoldSpec(.heart,    36, 2.500)
    var cloud    = MoldSpec(.cloud,    36, 2.182)
    var oldBear  = MoldSpec(.oldBear,  24, 4.600)
    var newBear  = MoldSpec(.newBear,  35, 3.946)
    var mushroom = MoldSpec(.mushroom, 15, 3.000)

    static let defaultMoldSpecs: [GummyShape: MoldSpec] = [
        .circle:   MoldSpec(.circle,   35, 2.292),
        .star:     MoldSpec(.star,     28, 2.211),
        .heart:    MoldSpec(.heart,    36, 2.500),
        .cloud:    MoldSpec(.cloud,    36, 2.182),
        .oldBear:  MoldSpec(.oldBear,  24, 4.600),
        .newBear:  MoldSpec(.newBear,  35, 3.946),
        .mushroom: MoldSpec(.mushroom, 15, 3.000),
    ]

    func moldVolumeIsDefault(for shape: GummyShape) -> Bool {
        guard let def = Self.defaultMoldSpecs[shape] else { return true }
        return spec(for: shape).volumeML == def.volumeML
    }

    func moldCountIsDefault(for shape: GummyShape) -> Bool {
        guard let def = Self.defaultMoldSpecs[shape] else { return true }
        return spec(for: shape).count == def.count
    }

    func resetMoldVolume(for shape: GummyShape) {
        guard let def = Self.defaultMoldSpecs[shape] else { return }
        var s = spec(for: shape)
        s.volumeML = def.volumeML
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
        loadDesignColorOverrides()
        loadUserThemes()
        loadContainerTareWeights()
        loadContainers()
        loadScales()
        loadDefaultScaleOverrides()
        loadSavedDefaults()
        if let raw = UserDefaults.standard.string(forKey: "numericInputMode"),
           let mode = NumericInputMode(rawValue: raw) {
            self.numericInputMode = mode
        }
        CMTheme.isDark = true
    }

    // MARK: Sugar Ratios

    /// Glucose syrup : granulated sugar by mass (1.0 = equal parts).
    var glucoseToSugarMassRatio: Double = 1.000

    var glucoseToSugarVolumeRatio: Double {
        glucoseToSugarMassRatio * (densitySucrose / densityGlucoseSyrup)
    }

    // MARK: Additives (volume % of total mix)

    var potassiumSorbatePercent: Double = 0.096
    var citricAcidPercent: Double = 0.786
    var additivesInputAsMassPercent: Bool = false

    // MARK: Mix Ratios

    /// Water : gelatin mass ratio for bloom hydration.
    var waterToGelatinMassRatio: Double = 3.000
    /// Water mass % in the sugar mix (drives sugar-to-water mass ratio).
    var waterMassPercentInSugarMix: Double = 17.34

    // MARK: Overage (display-only; does NOT enter the batch calculator)

    var sugarMixtureOveragePercent: Double = 5.0

    // MARK: LSD-Specific

    var lsdTransferWaterML: Double = 1.000
    var defaultLsdUgPerTab: Double = 117.0

    // MARK: Derived Ratios

    /// Sugar : water mass ratio, derived from `waterMassPercentInSugarMix`.
    var sugarToWaterMassRatio: Double {
        guard waterMassPercentInSugarMix > 0 else { return 0 }
        return (100.0 / waterMassPercentInSugarMix) - 1.0
    }

    /// Arithmetic mean of glucose syrup and granulated sugar densities.
    var averageSugarDensity: Double {
        (densityGlucoseSyrup + densitySucrose) / 2.0
    }

    /// Sugar mix density: ρ_mix = 1/(φ+1) · ρ_water + φ/(φ+1) · ρ_sugar.
    var sugarMixDensity: Double {
        let phi = sugarToWaterMassRatio
        return (1.0 / (phi + 1.0)) * densityWater
             + (phi / (phi + 1.0)) * averageSugarDensity
    }

    /// Estimated density of the final combined gummy mixture (g/mL).
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
        potassiumSorbatePercent == 0.096 && citricAcidPercent == 0.786
    }

    func resetAdditivesToDefault() {
        potassiumSorbatePercent = 0.096
        citricAcidPercent = 0.786
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

    private func batchIDString(for index: Int) -> String {
        let first = Character(UnicodeScalar(65 + (index / 26) % 26)!)
        let second = Character(UnicodeScalar(65 + index % 26)!)
        return String(first) + String(second)
    }

    /// Parse a two-letter batch ID back to its base-26 index, or nil if invalid.
    private func batchIDIndex(for id: String) -> Int? {
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

    // MARK: - Container Tare Weights

    /// Named beaker containers with factory-default tare masses.
    struct BeakerContainer: Identifiable, Codable, Equatable {
        var id: String   // dictionary key, e.g. "Beaker 5ml"
        var name: String // display name
        var tareWeight: Double // tare mass in grams

        static let factoryDefaults: [BeakerContainer] = [
            BeakerContainer(id: "Beaker 5ml",   name: "Beaker 5ml",   tareWeight: 6.105),
            BeakerContainer(id: "Beaker 10ml",  name: "Beaker 10ml",  tareWeight: 8.560),
            BeakerContainer(id: "Beaker 25ml",  name: "Beaker 25ml",  tareWeight: 20.631),
            BeakerContainer(id: "Beaker 50ml",  name: "Beaker 50ml",  tareWeight: 29.312),
            BeakerContainer(id: "Beaker 150ml", name: "Beaker 150ml", tareWeight: 65.358),
            BeakerContainer(id: "Beaker 250ml", name: "Beaker 250ml", tareWeight: 103.000),
            BeakerContainer(id: "Beaker 500ml", name: "Beaker 500ml", tareWeight: 161.130),
        ]
    }

    static let factoryContainers: [BeakerContainer] = [
        BeakerContainer(id: "Beaker 5ml",   name: "Beaker 5ml",   tareWeight: 6.105),
        BeakerContainer(id: "Beaker 10ml",  name: "Beaker 10ml",  tareWeight: 8.560),
        BeakerContainer(id: "Beaker 25ml",  name: "Beaker 25ml",  tareWeight: 20.631),
        BeakerContainer(id: "Beaker 50ml",  name: "Beaker 50ml",  tareWeight: 29.312),
        BeakerContainer(id: "Beaker 150ml", name: "Beaker 150ml", tareWeight: 65.358),
        BeakerContainer(id: "Beaker 250ml", name: "Beaker 250ml", tareWeight: 103.000),
        BeakerContainer(id: "Beaker 500ml", name: "Beaker 500ml", tareWeight: 161.130),
    ]

    /// Backward-compatible alias used by existing code.
    static var beakerContainers: [BeakerContainer] { factoryContainers }

    /// The live, user-editable list of containers. Persisted to UserDefaults.
    var containers: [BeakerContainer] = BeakerContainer.factoryDefaults {
        didSet { saveContainers() }
    }

    /// Saved tare weights for containers, persisted in UserDefaults.
    /// Kept for backward compatibility with overrides on factory containers.
    var containerTareWeights: [String: Double] = [:] {
        didSet { saveContainerTareWeights() }
    }

    private static let containerTareKey = "containerTareWeights"
    private static let containersKey = "labContainers"

    func containerTare(for label: String) -> Double {
        // First check the dynamic containers list
        if let container = containers.first(where: { $0.id == label }) {
            // If there's an override in the legacy dict, use it; otherwise use the container's own tare
            if let saved = containerTareWeights[label] { return saved }
            return container.tareWeight
        }
        // Fall back to factory default for known beakers
        if let beaker = Self.factoryContainers.first(where: { $0.id == label }) {
            if let saved = containerTareWeights[label] { return saved }
            return beaker.tareWeight
        }
        return 0
    }

    func setContainerTare(_ value: Double, for label: String) {
        // Update the dynamic container if it exists
        if let idx = containers.firstIndex(where: { $0.id == label }) {
            containers[idx].tareWeight = value
        }
        containerTareWeights[label] = value
    }

    func resetContainerTare(for label: String) {
        containerTareWeights.removeValue(forKey: label)
        // Reset to factory tare if it's a factory container
        if let factory = Self.factoryContainers.first(where: { $0.id == label }),
           let idx = containers.firstIndex(where: { $0.id == label }) {
            containers[idx].tareWeight = factory.tareWeight
        }
    }

    func resetAllContainerTares() {
        containerTareWeights = [:]
        containers = Self.factoryContainers
    }

    /// Whether a container's tare has been overridden from its factory default.
    func containerTareIsOverridden(for label: String) -> Bool {
        guard let factory = Self.factoryContainers.first(where: { $0.id == label }) else {
            // User-added container — not "overridden" in the factory sense
            return false
        }
        if let container = containers.first(where: { $0.id == label }) {
            return container.tareWeight != factory.tareWeight
        }
        return containerTareWeights[label] != nil
    }

    /// Whether a container is user-added (not in factory defaults).
    func containerIsUserAdded(for label: String) -> Bool {
        Self.factoryContainers.first(where: { $0.id == label }) == nil
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

    private func saveContainers() {
        if let data = try? JSONEncoder().encode(containers) {
            UserDefaults.standard.set(data, forKey: Self.containersKey)
        }
    }

    private func loadContainers() {
        guard let data = UserDefaults.standard.data(forKey: Self.containersKey),
              let saved = try? JSONDecoder().decode([BeakerContainer].self, from: data) else { return }
        containers = saved
        if containers.isEmpty { containers = Self.factoryContainers }
    }

    // MARK: - Laboratory Scales

    static let factoryScales: [ScaleSpec] = [
        ScaleSpec(id: "A", name: "Scale A", resolution: 0.001, maxCapacity: 100),
        ScaleSpec(id: "B", name: "Scale B", resolution: 0.01,  maxCapacity: 500),
        ScaleSpec(id: "C", name: "Scale C", resolution: 0.1,   maxCapacity: 5000),
    ]

    var scales: [ScaleSpec] = ScaleSpec.factoryDefaults {
        didSet { saveScales() }
    }

    private static let scalesKey = "labScales"

    private func saveScales() {
        let dicts: [[String: Any]] = scales.map { [
            "id": $0.id, "name": $0.name,
            "resolution": $0.resolution, "maxCapacity": $0.maxCapacity,
        ] }
        if let data = try? JSONSerialization.data(withJSONObject: dicts) {
            UserDefaults.standard.set(data, forKey: Self.scalesKey)
        }
    }

    private func loadScales() {
        guard let data = UserDefaults.standard.data(forKey: Self.scalesKey),
              let dicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        scales = dicts.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let res = dict["resolution"] as? Double,
                  let cap = dict["maxCapacity"] as? Double else { return nil }
            return ScaleSpec(id: id, name: name, resolution: res, maxCapacity: cap)
        }
        if scales.isEmpty { scales = Self.factoryScales }
    }

    /// Recommends the best scale for a given mass: the most precise scale whose capacity >= mass.
    func recommendedScale(forMassGrams mass: Double) -> ScaleSpec? {
        scales
            .sorted { $0.resolution < $1.resolution }
            .first { $0.maxCapacity >= mass }
    }

    /// User-overridden default scale IDs per resolution tier. Key = resolution rawValue string.
    /// When empty for a given resolution, the auto-computed default is used.
    var defaultScaleOverrides: [String: String] = [:] {
        didSet { saveDefaultScaleOverrides() }
    }

    private static let defaultScaleOverridesKey = "defaultScaleOverrides"

    /// The default scale for a resolution tier. If the user has overridden it, returns that;
    /// otherwise returns the scale with the matching resolution that has the largest capacity.
    func defaultScale(for resolution: MeasurementResolution) -> ScaleSpec? {
        let key = String(resolution.rawValue)
        if let overrideID = defaultScaleOverrides[key],
           let scale = scales.first(where: { $0.id == overrideID }) {
            return scale
        }
        // Auto: among scales at this resolution, pick the one with the largest capacity
        return autoDefaultScale(for: resolution)
    }

    /// Auto-computed default: the scale at the given resolution with the largest max capacity.
    func autoDefaultScale(for resolution: MeasurementResolution) -> ScaleSpec? {
        scales
            .filter { $0.resolution == resolution.rawValue }
            .max(by: { $0.maxCapacity < $1.maxCapacity })
    }

    /// Set a user override for the default scale at a given resolution.
    func setDefaultScale(_ scaleID: String, for resolution: MeasurementResolution) {
        let key = String(resolution.rawValue)
        // If the override matches the auto-computed default, remove it (no override needed)
        if let auto = autoDefaultScale(for: resolution), auto.id == scaleID {
            defaultScaleOverrides.removeValue(forKey: key)
        } else {
            defaultScaleOverrides[key] = scaleID
        }
    }

    /// Whether the user has overridden the default scale for a resolution.
    func defaultScaleIsOverridden(for resolution: MeasurementResolution) -> Bool {
        let key = String(resolution.rawValue)
        return defaultScaleOverrides[key] != nil
    }

    /// Reset a single resolution's default scale back to auto.
    func resetDefaultScale(for resolution: MeasurementResolution) {
        let key = String(resolution.rawValue)
        defaultScaleOverrides.removeValue(forKey: key)
    }

    private func saveDefaultScaleOverrides() {
        if let data = try? JSONEncoder().encode(defaultScaleOverrides) {
            UserDefaults.standard.set(data, forKey: Self.defaultScaleOverridesKey)
        }
    }

    private func loadDefaultScaleOverrides() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultScaleOverridesKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            defaultScaleOverrides = dict
        }
    }

    /// Recommends the smallest beaker container whose nominal volume can hold the given volume.
    func recommendedBeaker(forVolumeML volume: Double) -> BeakerContainer? {
        // Parse the mL capacity from the container name (e.g. "Beaker 50ml" → 50)
        containers
            .compactMap { container -> (BeakerContainer, Double)? in
                let digits = container.name.filter { $0.isNumber }
                guard let capacity = Double(digits), capacity > 0 else { return nil }
                return (container, capacity)
            }
            .sorted { $0.1 < $1.1 }  // sort by capacity ascending
            .first { $0.1 >= volume }?.0
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

    var accentTheme: AccentTheme = .deepCurrent {
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

    // MARK: - Design Language Colors

    /// Design language role identifiers for persistence.
    enum DesignColorRole: String, CaseIterable, Identifiable, Codable {
        case primary         = "Primary"
        case alert           = "Alert"
        case primaryAccent   = "Primary Accent"
        case secondaryAccent = "Secondary Accent"
        case measurement     = "Measurement"
        case keypadAccent    = "Keypad Accent"
        case bodyText        = "Body Text"
        case detailText      = "Detail Text"

        var id: String { rawValue }

        /// Factory default color for each role (as RGB).
        var factoryColor: Color {
            switch self {
            case .primary:         return Color(red: 0.031, green: 0.514, blue: 0.584)  // Deep Current
            case .alert:           return Color(red: 0.929, green: 0.278, blue: 0.290)  // Strawberry Red
            case .primaryAccent:   return Color(red: 1.000, green: 0.000, blue: 0.529)  // Fuchsia Flare
            case .secondaryAccent: return Color(red: 0.920, green: 0.680, blue: 0.320)  // Amber Gold
            case .measurement:     return Color(red: 0.0, green: 0.85, blue: 1.0)        // HP Cyan
            case .keypadAccent:    return Color(red: 0.38, green: 0.45, blue: 0.95)     // Indigo (matches CMTheme.defaultAccent)
            case .bodyText:        return Color.white.opacity(0.92)                      // textPrimary dark
            case .detailText:      return Color.white.opacity(0.22)                      // textTertiary dark
            }
        }

        /// Factory default HSB values.
        var factoryHSB: (h: Double, s: Double, b: Double) {
            switch self {
            case .primary:         return (0.521, 0.947, 0.584)  // Deep Current
            case .alert:           return (0.003, 0.699, 0.929)  // Strawberry Red
            case .primaryAccent:   return (0.917, 1.000, 1.000)  // Fuchsia Flare
            case .secondaryAccent: return (0.100, 0.652, 0.920)  // Amber Gold
            case .measurement:     return (0.528, 1.000, 1.000)  // HP Cyan
            case .keypadAccent:    return (0.640, 0.600, 0.950)  // Indigo
            case .bodyText:        return (0.000, 0.000, 0.920)  // White 92%
            case .detailText:      return (0.000, 0.000, 0.220)  // White 22%
            }
        }

        /// Description of what this color is used for.
        var usage: String {
            switch self {
            case .primary:         return "Section titles & headers"
            case .alert:           return "Alerts, locks & destructive actions"
            case .primaryAccent:   return "Overage data & corrections"
            case .secondaryAccent: return "Active transfer & secondary data"
            case .measurement:     return "HP measurement boxes, labels & component text"
            case .keypadAccent:    return "Custom numeric keypad Done button & field highlight"
            case .bodyText:        return "Main body text throughout the app"
            case .detailText:      return "Small fine print, footnotes & captions"
            }
        }

        /// Preset color palette for this role — tappable swatches in the editor.
        var presets: [DesignColorPreset] {
            switch self {
            case .primary:
                return [
                    DesignColorPreset("Deep Current",   h: 0.521, s: 0.947, b: 0.584),
                    DesignColorPreset("Glacier Bay",    h: 0.540, s: 0.600, b: 0.750),
                    DesignColorPreset("Cobalt Dusk",    h: 0.620, s: 0.750, b: 0.650),
                    DesignColorPreset("Jade Mist",      h: 0.450, s: 0.560, b: 0.827),
                    DesignColorPreset("Slate Iris",     h: 0.710, s: 0.400, b: 0.600),
                    DesignColorPreset("Midnight Teal",  h: 0.500, s: 0.850, b: 0.420),
                    DesignColorPreset("Ocean Abyss",    h: 0.580, s: 0.800, b: 0.500),
                    DesignColorPreset("Arctic Sage",    h: 0.390, s: 0.350, b: 0.700),
                    DesignColorPreset("Steel Violet",   h: 0.750, s: 0.450, b: 0.550),
                    DesignColorPreset("Driftwood",      h: 0.080, s: 0.250, b: 0.650),
                ]
            case .alert:
                return [
                    DesignColorPreset("Strawberry Red", h: 0.003, s: 0.699, b: 0.929),
                    DesignColorPreset("Coral Flame",    h: 0.020, s: 0.750, b: 0.950),
                    DesignColorPreset("Neon Rose",      h: 0.950, s: 0.800, b: 1.000),
                    DesignColorPreset("Ember Glow",     h: 0.040, s: 0.850, b: 0.900),
                    DesignColorPreset("Blood Orange",   h: 0.030, s: 0.900, b: 0.950),
                    DesignColorPreset("Sunset Blush",   h: 0.015, s: 0.550, b: 1.000),
                    DesignColorPreset("Vermillion",     h: 0.060, s: 0.850, b: 0.890),
                    DesignColorPreset("Cherry Blossom", h: 0.970, s: 0.500, b: 0.950),
                    DesignColorPreset("Brick Dust",     h: 0.010, s: 0.650, b: 0.750),
                    DesignColorPreset("Ruby Spark",     h: 0.980, s: 0.800, b: 0.850),
                ]
            case .primaryAccent:
                return [
                    DesignColorPreset("Fuchsia Flare",  h: 0.917, s: 1.000, b: 1.000),
                    DesignColorPreset("Hot Magenta",    h: 0.900, s: 0.900, b: 0.950),
                    DesignColorPreset("Electric Orchid", h: 0.830, s: 0.750, b: 1.000),
                    DesignColorPreset("Neon Grape",     h: 0.800, s: 0.800, b: 0.900),
                    DesignColorPreset("Candy Pink",     h: 0.940, s: 0.650, b: 1.000),
                    DesignColorPreset("Bubblegum",      h: 0.930, s: 0.500, b: 1.000),
                    DesignColorPreset("Plum Pulse",     h: 0.820, s: 0.600, b: 0.800),
                    DesignColorPreset("Raspberry",      h: 0.940, s: 0.850, b: 0.850),
                    DesignColorPreset("Violet Storm",   h: 0.780, s: 0.700, b: 0.850),
                    DesignColorPreset("Peony",          h: 0.910, s: 0.450, b: 0.950),
                ]
            case .secondaryAccent:
                return [
                    DesignColorPreset("Amber Gold",     h: 0.100, s: 0.652, b: 0.920),
                    DesignColorPreset("Honey Glaze",    h: 0.110, s: 0.550, b: 0.950),
                    DesignColorPreset("Saffron",        h: 0.120, s: 0.800, b: 0.950),
                    DesignColorPreset("Burnt Sienna",   h: 0.060, s: 0.700, b: 0.780),
                    DesignColorPreset("Marigold",       h: 0.130, s: 0.900, b: 1.000),
                    DesignColorPreset("Champagne",      h: 0.110, s: 0.350, b: 0.950),
                    DesignColorPreset("Caramel",        h: 0.080, s: 0.600, b: 0.750),
                    DesignColorPreset("Candlelight",    h: 0.140, s: 0.750, b: 1.000),
                    DesignColorPreset("Copper Patina",  h: 0.070, s: 0.550, b: 0.700),
                    DesignColorPreset("Tangerine Dusk", h: 0.055, s: 0.800, b: 0.950),
                ]
            case .measurement:
                return [
                    DesignColorPreset("HP Cyan",        h: 0.528, s: 1.000, b: 1.000),
                    DesignColorPreset("Electric Blue",  h: 0.580, s: 0.900, b: 1.000),
                    DesignColorPreset("Aqua Pulse",     h: 0.500, s: 0.850, b: 0.950),
                    DesignColorPreset("Neon Mint",      h: 0.450, s: 0.800, b: 1.000),
                    DesignColorPreset("Deep Sapphire",  h: 0.600, s: 0.900, b: 0.800),
                    DesignColorPreset("Teal Glow",      h: 0.490, s: 0.750, b: 0.850),
                    DesignColorPreset("Frost",          h: 0.540, s: 0.400, b: 0.900),
                    DesignColorPreset("Cerulean",       h: 0.550, s: 0.800, b: 0.900),
                    DesignColorPreset("Sky Wire",       h: 0.560, s: 0.600, b: 1.000),
                    DesignColorPreset("Lagoon",         h: 0.480, s: 0.700, b: 0.750),
                ]
            case .keypadAccent:
                return [
                    DesignColorPreset("Indigo",         h: 0.640, s: 0.600, b: 0.950),
                    DesignColorPreset("Violet",         h: 0.750, s: 0.550, b: 0.900),
                    DesignColorPreset("Royal Blue",     h: 0.600, s: 0.700, b: 0.950),
                    DesignColorPreset("Teal",           h: 0.500, s: 0.650, b: 0.850),
                    DesignColorPreset("Emerald",        h: 0.400, s: 0.700, b: 0.800),
                    DesignColorPreset("Coral",          h: 0.030, s: 0.600, b: 0.950),
                    DesignColorPreset("Sunset",         h: 0.080, s: 0.650, b: 0.950),
                    DesignColorPreset("Rose",           h: 0.940, s: 0.550, b: 0.950),
                    DesignColorPreset("Lavender",       h: 0.720, s: 0.400, b: 0.900),
                    DesignColorPreset("Gold",           h: 0.120, s: 0.700, b: 0.950),
                ]
            case .bodyText:
                return [
                    DesignColorPreset("Cloud White",    h: 0.000, s: 0.000, b: 0.920),
                    DesignColorPreset("Warm Cream",     h: 0.100, s: 0.080, b: 0.950),
                    DesignColorPreset("Cool Silver",    h: 0.600, s: 0.050, b: 0.850),
                    DesignColorPreset("Pale Gold",      h: 0.120, s: 0.100, b: 0.900),
                    DesignColorPreset("Soft Lavender",  h: 0.750, s: 0.060, b: 0.880),
                    DesignColorPreset("Ice Blue",       h: 0.550, s: 0.070, b: 0.900),
                    DesignColorPreset("Bone",           h: 0.080, s: 0.060, b: 0.880),
                    DesignColorPreset("Pearl",          h: 0.000, s: 0.000, b: 0.960),
                    DesignColorPreset("Moonstone",      h: 0.580, s: 0.040, b: 0.820),
                    DesignColorPreset("Ash",            h: 0.000, s: 0.000, b: 0.700),
                ]
            case .detailText:
                return [
                    DesignColorPreset("Dim",            h: 0.000, s: 0.000, b: 0.220),
                    DesignColorPreset("Muted Silver",   h: 0.600, s: 0.050, b: 0.350),
                    DesignColorPreset("Warm Dust",      h: 0.080, s: 0.080, b: 0.300),
                    DesignColorPreset("Cool Slate",     h: 0.580, s: 0.060, b: 0.280),
                    DesignColorPreset("Graphite",       h: 0.000, s: 0.000, b: 0.350),
                    DesignColorPreset("Faded Sage",     h: 0.400, s: 0.080, b: 0.300),
                    DesignColorPreset("Charcoal",       h: 0.000, s: 0.000, b: 0.180),
                    DesignColorPreset("Pewter",         h: 0.600, s: 0.040, b: 0.400),
                    DesignColorPreset("Smoke",          h: 0.000, s: 0.000, b: 0.280),
                    DesignColorPreset("Whisper",        h: 0.000, s: 0.000, b: 0.150),
                ]
            }
        }
    }

    /// A named preset color option within a design role palette.
    struct DesignColorPreset: Identifiable, Codable, Equatable {
        let id: String
        let name: String
        let hue: Double
        let saturation: Double
        let brightness: Double

        var color: Color {
            Color(hue: hue, saturation: saturation, brightness: brightness)
        }

        init(_ name: String, h: Double, s: Double, b: Double) {
            self.id = name
            self.name = name
            self.hue = h
            self.saturation = s
            self.brightness = b
        }
    }

    /// A design theme — a named set of colors for all design roles.
    struct DesignTheme: Identifiable, Codable, Equatable {
        let id: String
        var name: String
        let primaryColor: DesignColorPreset
        let alert: DesignColorPreset
        let primaryAccent: DesignColorPreset
        let secondaryAccent: DesignColorPreset
        let measurement: DesignColorPreset
        let keypadAccent: DesignColorPreset
        let bodyText: DesignColorPreset
        let detailText: DesignColorPreset

        /// Decode with migration from old property names.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id           = try c.decode(String.self, forKey: .id)
            name         = try c.decode(String.self, forKey: .name)
            primaryColor = try c.decode(DesignColorPreset.self, forKey: .primaryColor)
            // Migration: old "primaryAccent" → new "alert"
            alert        = try c.decodeIfPresent(DesignColorPreset.self, forKey: .alert)
                ?? (try c.decodeIfPresent(DesignColorPreset.self, forKey: .primaryAccent))
                ?? DesignColorPreset("Strawberry Red", h: 0.003, s: 0.699, b: 0.929)
            // Migration: old "secondary" → new "primaryAccent"
            primaryAccent = try c.decodeIfPresent(DesignColorPreset.self, forKey: .primaryAccent)
                ?? (try c.decodeIfPresent(DesignColorPreset.self, forKey: .secondaryAccent))
                ?? DesignColorPreset("Fuchsia Flare", h: 0.917, s: 1.000, b: 1.000)
            // Migration: old "tertiary" → new "secondaryAccent"
            secondaryAccent = try c.decodeIfPresent(DesignColorPreset.self, forKey: .secondaryAccent)
                ?? DesignColorPreset("Amber Gold", h: 0.100, s: 0.652, b: 0.920)
            measurement  = try c.decodeIfPresent(DesignColorPreset.self, forKey: .measurement)
                ?? DesignColorPreset("HP Cyan", h: 0.528, s: 1.000, b: 1.000)
            keypadAccent = try c.decodeIfPresent(DesignColorPreset.self, forKey: .keypadAccent)
                ?? DesignColorPreset("Indigo", h: 0.640, s: 0.600, b: 0.950)
            bodyText     = try c.decode(DesignColorPreset.self, forKey: .bodyText)
            detailText   = try c.decode(DesignColorPreset.self, forKey: .detailText)
        }

        init(id: String, name: String, primaryColor: DesignColorPreset, alert: DesignColorPreset,
             primaryAccent: DesignColorPreset, secondaryAccent: DesignColorPreset,
             measurement: DesignColorPreset, keypadAccent: DesignColorPreset = DesignColorPreset("Indigo", h: 0.640, s: 0.600, b: 0.950),
             bodyText: DesignColorPreset, detailText: DesignColorPreset) {
            self.id = id; self.name = name; self.primaryColor = primaryColor
            self.alert = alert; self.primaryAccent = primaryAccent
            self.secondaryAccent = secondaryAccent; self.measurement = measurement
            self.keypadAccent = keypadAccent
            self.bodyText = bodyText; self.detailText = detailText
        }

        func color(for role: DesignColorRole) -> DesignColorPreset {
            switch role {
            case .primary:         return primaryColor
            case .alert:           return alert
            case .primaryAccent:   return primaryAccent
            case .secondaryAccent: return secondaryAccent
            case .measurement:     return measurement
            case .keypadAccent:    return keypadAccent
            case .bodyText:        return bodyText
            case .detailText:      return detailText
            }
        }
    }

    /// Built-in design themes.
    static let designThemes: [DesignTheme] = [
        DesignTheme(
            id: "factory", name: "Factory",
            primaryColor: DesignColorPreset("Deep Current",   h: 0.521, s: 0.947, b: 0.584),
            alert:     DesignColorPreset("Strawberry Red", h: 0.003, s: 0.699, b: 0.929),
            primaryAccent: DesignColorPreset("Fuchsia Flare",  h: 0.917, s: 1.000, b: 1.000),
            secondaryAccent: DesignColorPreset("Amber Gold",     h: 0.100, s: 0.652, b: 0.920),
            measurement: DesignColorPreset("HP Cyan",      h: 0.528, s: 1.000, b: 1.000),
            bodyText:  DesignColorPreset("Cloud White",    h: 0.000, s: 0.000, b: 0.920),
            detailText: DesignColorPreset("Dim",           h: 0.000, s: 0.000, b: 0.220)
        ),
        DesignTheme(
            id: "midnight", name: "Midnight",
            primaryColor: DesignColorPreset("Ocean Abyss",    h: 0.580, s: 0.800, b: 0.500),
            alert:     DesignColorPreset("Neon Rose",      h: 0.950, s: 0.800, b: 1.000),
            primaryAccent: DesignColorPreset("Electric Orchid", h: 0.830, s: 0.750, b: 1.000),
            secondaryAccent: DesignColorPreset("Candlelight",    h: 0.140, s: 0.750, b: 1.000),
            measurement: DesignColorPreset("Electric Blue", h: 0.580, s: 0.900, b: 1.000),
            bodyText:  DesignColorPreset("Cool Silver",    h: 0.600, s: 0.050, b: 0.850),
            detailText: DesignColorPreset("Cool Slate",    h: 0.580, s: 0.060, b: 0.280)
        ),
        DesignTheme(
            id: "ember", name: "Ember",
            primaryColor: DesignColorPreset("Driftwood",      h: 0.080, s: 0.250, b: 0.650),
            alert:     DesignColorPreset("Blood Orange",   h: 0.030, s: 0.900, b: 0.950),
            primaryAccent: DesignColorPreset("Hot Magenta",    h: 0.900, s: 0.900, b: 0.950),
            secondaryAccent: DesignColorPreset("Saffron",        h: 0.120, s: 0.800, b: 0.950),
            measurement: DesignColorPreset("Aqua Pulse",   h: 0.500, s: 0.850, b: 0.950),
            bodyText:  DesignColorPreset("Warm Cream",     h: 0.100, s: 0.080, b: 0.950),
            detailText: DesignColorPreset("Warm Dust",     h: 0.080, s: 0.080, b: 0.300)
        ),
        DesignTheme(
            id: "arctic", name: "Arctic",
            primaryColor: DesignColorPreset("Glacier Bay",    h: 0.540, s: 0.600, b: 0.750),
            alert:     DesignColorPreset("Cherry Blossom", h: 0.970, s: 0.500, b: 0.950),
            primaryAccent: DesignColorPreset("Bubblegum",      h: 0.930, s: 0.500, b: 1.000),
            secondaryAccent: DesignColorPreset("Champagne",      h: 0.110, s: 0.350, b: 0.950),
            measurement: DesignColorPreset("Frost",        h: 0.540, s: 0.400, b: 0.900),
            bodyText:  DesignColorPreset("Ice Blue",       h: 0.550, s: 0.070, b: 0.900),
            detailText: DesignColorPreset("Muted Silver",  h: 0.600, s: 0.050, b: 0.350)
        ),
        DesignTheme(
            id: "noir", name: "Noir",
            primaryColor: DesignColorPreset("Steel Violet",   h: 0.750, s: 0.450, b: 0.550),
            alert:     DesignColorPreset("Ember Glow",     h: 0.040, s: 0.850, b: 0.900),
            primaryAccent: DesignColorPreset("Plum Pulse",     h: 0.820, s: 0.600, b: 0.800),
            secondaryAccent: DesignColorPreset("Burnt Sienna",   h: 0.060, s: 0.700, b: 0.780),
            measurement: DesignColorPreset("Deep Sapphire", h: 0.600, s: 0.900, b: 0.800),
            bodyText:  DesignColorPreset("Ash",            h: 0.000, s: 0.000, b: 0.700),
            detailText: DesignColorPreset("Charcoal",      h: 0.000, s: 0.000, b: 0.180)
        ),
        DesignTheme(
            id: "botanical", name: "Botanical",
            primaryColor: DesignColorPreset("Jade Mist",      h: 0.450, s: 0.560, b: 0.827),
            alert:     DesignColorPreset("Coral Flame",    h: 0.020, s: 0.750, b: 0.950),
            primaryAccent: DesignColorPreset("Peony",          h: 0.910, s: 0.450, b: 0.950),
            secondaryAccent: DesignColorPreset("Honey Glaze",    h: 0.110, s: 0.550, b: 0.950),
            measurement: DesignColorPreset("Teal Glow",    h: 0.490, s: 0.750, b: 0.850),
            bodyText:  DesignColorPreset("Pale Gold",      h: 0.120, s: 0.100, b: 0.900),
            detailText: DesignColorPreset("Faded Sage",    h: 0.400, s: 0.080, b: 0.300)
        ),
    ]

    /// Apply a design theme, setting all five roles at once.
    func applyDesignTheme(_ theme: DesignTheme) {
        for role in DesignColorRole.allCases {
            let preset = theme.color(for: role)
            setDesignColor(hue: preset.hue, saturation: preset.saturation, brightness: preset.brightness, for: role)
        }
    }

    /// Returns the ID of the currently active design theme, if all roles match a built-in or user theme.
    /// Returns `nil` if no overrides (factory defaults) → matches "factory", or if custom.
    var activeDesignThemeID: String? {
        // If no overrides at all, the Factory theme is effectively active
        if designColorOverrides.isEmpty { return "factory" }
        let allThemes = Self.designThemes + userThemes
        for theme in allThemes {
            let allMatch = DesignColorRole.allCases.allSatisfy { role in
                let preset = theme.color(for: role)
                if let ov = designColorOverrides[role.rawValue] {
                    return abs(preset.hue - ov.hue) < 0.005
                        && abs(preset.saturation - ov.saturation) < 0.005
                        && abs(preset.brightness - ov.brightness) < 0.005
                } else {
                    // No override means factory default for this role
                    let factory = role.factoryHSB
                    return abs(preset.hue - factory.h) < 0.005
                        && abs(preset.saturation - factory.s) < 0.005
                        && abs(preset.brightness - factory.b) < 0.005
                }
            }
            if allMatch { return theme.id }
        }
        return nil
    }

    /// Persisted HSB overrides for design language colors, keyed by role rawValue.
    struct DesignColorOverride: Codable, Equatable {
        var hue: Double
        var saturation: Double
        var brightness: Double

        var color: Color {
            Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    var designColorOverrides: [String: DesignColorOverride] = [:] {
        didSet { saveDesignColorOverrides() }
    }

    /// Resolved color for a design language role.
    func designColor(for role: DesignColorRole) -> Color {
        if let override = designColorOverrides[role.rawValue] {
            return override.color
        }
        return role.factoryColor
    }

    /// The display name for the current design color selection for a role.
    func designColorDisplayName(for role: DesignColorRole) -> String {
        if let override = designColorOverrides[role.rawValue] {
            // Check if it matches a preset
            for preset in role.presets {
                if abs(preset.hue - override.hue) < 0.005
                    && abs(preset.saturation - override.saturation) < 0.005
                    && abs(preset.brightness - override.brightness) < 0.005 {
                    return preset.name
                }
            }
            return "Custom"
        }
        return role.presets.first?.name ?? "Default"
    }

    /// Whether a design language color has been overridden from its factory default.
    func designColorIsOverridden(_ role: DesignColorRole) -> Bool {
        designColorOverrides[role.rawValue] != nil
    }

    /// Reset a single design language color back to factory.
    func resetDesignColor(_ role: DesignColorRole) {
        designColorOverrides.removeValue(forKey: role.rawValue)
    }

    /// Reset all design language colors back to factory.
    func resetAllDesignColors() {
        designColorOverrides = [:]
    }

    /// Set a custom HSB value for a design language role.
    func setDesignColor(hue: Double, saturation: Double, brightness: Double, for role: DesignColorRole) {
        designColorOverrides[role.rawValue] = DesignColorOverride(
            hue: hue, saturation: saturation, brightness: brightness
        )
    }

    /// Select a preset color for a design role.
    func selectDesignPreset(_ preset: DesignColorPreset, for role: DesignColorRole) {
        setDesignColor(hue: preset.hue, saturation: preset.saturation, brightness: preset.brightness, for: role)
    }

    /// Convenience accessors for common design language colors.
    var designTitle: Color { designColor(for: .primary) }
    var designAlert: Color { designColor(for: .alert) }
    var designPrimaryAccent: Color { designColor(for: .primaryAccent) }
    var designSecondaryAccent: Color { designColor(for: .secondaryAccent) }
    var designMeasurement: Color { designColor(for: .measurement) }
    var designKeypadAccent: Color { designColor(for: .keypadAccent) }
    var designBodyText: Color { designColor(for: .bodyText) }
    var designDetailText: Color { designColor(for: .detailText) }

    private static let designColorOverridesKey = "designColorOverrides"

    private func saveDesignColorOverrides() {
        if let data = try? JSONEncoder().encode(designColorOverrides) {
            UserDefaults.standard.set(data, forKey: Self.designColorOverridesKey)
        }
    }

    private func loadDesignColorOverrides() {
        if let data = UserDefaults.standard.data(forKey: Self.designColorOverridesKey),
           var overrides = try? JSONDecoder().decode([String: DesignColorOverride].self, from: data) {
            // Migrate legacy "Title" key to "Primary"
            if let titleOverride = overrides.removeValue(forKey: "Title") {
                if overrides["Primary"] == nil {
                    overrides["Primary"] = titleOverride
                }
            }
            // Migrate renamed accent roles (v2):
            //   old "Primary Accent" → "Alert"
            //   old "Secondary Accent" → "Primary Accent"
            //   old "Tertiary Accent" → "Secondary Accent"
            // Detect pre-migration data by presence of "Tertiary Accent" key (removed in new schema).
            if overrides["Tertiary Accent"] != nil {
                let oldPrimary   = overrides.removeValue(forKey: "Primary Accent")
                let oldSecondary = overrides.removeValue(forKey: "Secondary Accent")
                let oldTertiary  = overrides.removeValue(forKey: "Tertiary Accent")
                if let v = oldPrimary   { overrides["Alert"] = v }
                if let v = oldSecondary { overrides["Primary Accent"] = v }
                if let v = oldTertiary  { overrides["Secondary Accent"] = v }
                // Re-save immediately to persist migration
                if let migrated = try? JSONEncoder().encode(overrides) {
                    UserDefaults.standard.set(migrated, forKey: Self.designColorOverridesKey)
                }
            }
            designColorOverrides = overrides
        }
    }

    // MARK: - User-Saved Design Themes

    var userThemes: [DesignTheme] = [] {
        didSet { saveUserThemes() }
    }

    private static let userThemesKey = "userDesignThemes"

    /// Save the current color selections as a new user theme.
    func saveCurrentAsTheme(name: String) {
        func presetForRole(_ role: DesignColorRole) -> DesignColorPreset {
            if let ov = designColorOverrides[role.rawValue] {
                // Check if it matches a named preset
                for preset in role.presets {
                    if abs(preset.hue - ov.hue) < 0.005
                        && abs(preset.saturation - ov.saturation) < 0.005
                        && abs(preset.brightness - ov.brightness) < 0.005 {
                        return preset
                    }
                }
                return DesignColorPreset("Custom", h: ov.hue, s: ov.saturation, b: ov.brightness)
            }
            let factory = role.factoryHSB
            return DesignColorPreset(role.presets.first?.name ?? "Default", h: factory.h, s: factory.s, b: factory.b)
        }

        let theme = DesignTheme(
            id: UUID().uuidString,
            name: name,
            primaryColor: presetForRole(.primary),
            alert: presetForRole(.alert),
            primaryAccent: presetForRole(.primaryAccent),
            secondaryAccent: presetForRole(.secondaryAccent),
            measurement: presetForRole(.measurement),
            keypadAccent: presetForRole(.keypadAccent),
            bodyText: presetForRole(.bodyText),
            detailText: presetForRole(.detailText)
        )
        userThemes.append(theme)
    }

    func deleteUserTheme(id: String) {
        userThemes.removeAll { $0.id == id }
    }

    func renameUserTheme(id: String, newName: String) {
        if let idx = userThemes.firstIndex(where: { $0.id == id }) {
            userThemes[idx].name = newName
        }
    }

    private func saveUserThemes() {
        if let data = try? JSONEncoder().encode(userThemes) {
            UserDefaults.standard.set(data, forKey: Self.userThemesKey)
        }
    }

    private func loadUserThemes() {
        if let data = UserDefaults.standard.data(forKey: Self.userThemesKey),
           let themes = try? JSONDecoder().decode([DesignTheme].self, from: data) {
            userThemes = themes
        }
    }

    // MARK: - Appearance Mode
    /// Dark mode is always on. Property kept for settings export/import compatibility.
    var isDarkMode: Bool = true

    // MARK: - Haptic Feedback
    var sliderVibrationsEnabled: Bool = true

    // MARK: - Numeric Input Mode
    /// Controls whether numeric fields use the custom floating keypad or the system keyboard.
    /// Default is `.auto` (custom keypad on iPad, system keyboard on iPhone).
    var numericInputMode: NumericInputMode = .auto {
        didSet { UserDefaults.standard.set(numericInputMode.rawValue, forKey: "numericInputMode") }
    }

    /// Whether the custom keypad should be used, resolved from the user's preference and device type.
    var useCustomKeypad: Bool {
        switch numericInputMode {
        case .keypad:   return true
        case .keyboard: return false
        case .auto:     return UIDevice.current.userInterfaceIdiom == .pad
        }
    }

    // MARK: - Slider Resolution
    /// Snap increment (in %) for blend-ratio sliders (colors, flavors, terpenes).
    /// Default is 5. Smaller values give finer control.
    var sliderResolution: Double = 5.0

    // MARK: - Double Vision (Slider Ghost Trail)
    /// Whether the double-vision ghost trail is visible on slider thumbs during drag.
    var doubleVisionEnabled: Bool = true
    /// Offset distance multiplier for ghost images. Higher = more spread.
    /// 1.0 = subtle, 2.0 = default, 4.0 = extreme.
    var doubleVisionIntensity: Double = 2.0
    /// Ghost trail fade-out time in seconds. Each ghost circle fades from full to zero
    /// over this duration. Higher = longer trails.
    var doubleVisionFadeTime: Double = 0.6
    /// Maximum number of ghost trail circles alive at once (3–20).
    var doubleVisionTrailCount: Int = 10

    // MARK: - Developer Mode

    var developerMode: Bool = true
    var expandDetailSectionsByDefault: Bool = false
    var syntheticDataSet1Enabled: Bool = true
    var syntheticMeasurementsEnabled: Bool = true

    /// Applies the "Tropical Punch" real batch dataset when developer mode is toggled on.
    func applyDevMode(to viewModel: BatchConfigViewModel) {
        // Shape & quantity — real batch: 1 tray of New Bear (35 wells)
        viewModel.selectedShape = .newBear
        viewModel.trayCount = 1
        viewModel.extraGummies = 0

        // Active substance — LSD 10 µg/gummy
        viewModel.selectedActive = .lsd
        viewModel.units = .ug
        viewModel.activeConcentration = 10.0
        viewModel.lsdUgPerTab = 117.0
        viewModel.additionalActiveWaterML = 1.0

        // Gelatin
        viewModel.gelatinPercentage = 5.225

        // Flavor oils: Lemonade 75%, Tropical Punch 25%
        viewModel.selectedFlavors = [:]
        viewModel.oilsLocked = false
        viewModel.terpenesLocked = false
        viewModel.flavorCompositionLocked = false
        viewModel.selectedFlavors[.oil(.lemonade)] = 75.0
        viewModel.selectedFlavors[.oil(.tropicalPunch)] = 25.0
        viewModel.flavorOilVolumePercent = 0.451

        // Terpenes: Pineapple 70%, Passionfruit 30%
        viewModel.selectedFlavors[.terpene(.pineapple)] = 70.0
        viewModel.selectedFlavors[.terpene(.passionfruit)] = 30.0
        viewModel.terpeneVolumePPM = 199.0

        // Colors: Coral 10%, Red 30%, Yellow 60%
        viewModel.selectedColors = [:]
        viewModel.colorsLocked = false
        viewModel.colorCompositionLocked = false
        viewModel.selectedColors[.coral] = 10.0
        viewModel.selectedColors[.red] = 30.0
        viewModel.selectedColors[.yellow] = 60.0
        viewModel.colorVolumePercent = 0.664

        // Lock all selections
        viewModel.oilsLocked = true
        viewModel.terpenesLocked = true
        viewModel.flavorCompositionLocked = true
        viewModel.colorsLocked = true
        viewModel.colorCompositionLocked = true

        // Auto-calculate the batch
        viewModel.batchCalculated = true
        viewModel.prePopulateRecommendedScales(systemConfig: self)
    }

    /// Reverts developer mode overrides (Tropical Punch dataset).
    func revertDevMode(to viewModel: BatchConfigViewModel) {
        // Clear the auto-selected flavors and colors
        viewModel.selectedFlavors = [:]
        viewModel.selectedColors = [:]
        viewModel.oilsLocked = false
        viewModel.terpenesLocked = false
        viewModel.flavorCompositionLocked = false
        viewModel.colorsLocked = false
        viewModel.colorCompositionLocked = false
    }

    /// Fills measurement fields with real data from the "Tropical Punch" batch (BA).
    func applySyntheticMeasurements(to viewModel: BatchConfigViewModel) {
        // Beaker (Empty) — real measurement
        viewModel.weightBeakerEmpty = 161.13

        // Beaker + Gelatin Mix
        viewModel.weightBeakerPlusGelatin = 194.0

        // Substrate + Sugar Mix
        viewModel.weightBeakerPlusSugar = 319.26

        // Substrate + Activation Mix
        viewModel.weightBeakerPlusActive = 320.55

        // Syringe (Clean)
        viewModel.weightSyringeEmpty = 137.36

        // Syringe + Gummy Mix
        viewModel.weightSyringeWithMix = 202.39

        // Syringe Gummy Mix Vol
        viewModel.volumeSyringeGummyMix = 50.0

        // Syringe + Residue
        viewModel.weightSyringeResidue = 137.14

        // Beaker + Residue
        viewModel.weightBeakerResidue = 167.30

        // Tray (Clean)
        viewModel.weightTrayClean = 74.04

        // Tray + Residue — not recorded in this batch
        viewModel.weightTrayPlusResidue = nil

        // Molds filled
        viewModel.weightMoldsFilled = 27.0

        // Extra gummy mix — not recorded
        viewModel.extraGummyMixGrams = nil

        // Density calibration — not performed in this batch
        viewModel.densitySyringeCleanSugar = nil
        viewModel.densitySyringePlusSugarMass = nil
        viewModel.densitySyringePlusSugarVol = nil
        viewModel.densitySyringeCleanGelatin = nil
        viewModel.densitySyringePlusGelatinMass = nil
        viewModel.densitySyringePlusGelatinVol = nil
        viewModel.densitySyringeCleanActive = nil
        viewModel.densitySyringePlusActiveMass = nil
        viewModel.densitySyringePlusActiveVol = nil

        // No additional measurements in this batch
        viewModel.additionalMeasurements = [
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 1"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 2"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 3"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 4"),
        ]

        // HP mode — not used in this batch
        viewModel.highPrecisionMode = true
        viewModel.hpSubstrateBeakerID = nil
        viewModel.hpSugarMixBeakerID = nil
        viewModel.hpActivationTrayID = nil
        viewModel.hpSubstrateScaleID = nil
        viewModel.hpSugarMixScaleID = nil
        viewModel.hpActivationScaleID = nil
        viewModel.hpGelatin = nil
        viewModel.hpGelatinWater = nil
        viewModel.hpGranulated = nil
        viewModel.hpGlucoseSyrup = nil
        viewModel.hpSugarWater = nil
        viewModel.hpCitricAcid = nil
        viewModel.hpActivationWater = nil
        viewModel.hpKSorbate = nil
        viewModel.hpFlavorOilsTerpsActive = nil
        viewModel.hpActivationTrayResidue = nil
        viewModel.hpSubstrateSugarTransfer = nil
        viewModel.hpSubstrateActivationTransfer = nil
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
        viewModel.extraGummyMixGrams = nil
        viewModel.densitySyringeCleanSugar = nil
        viewModel.densitySyringePlusSugarMass = nil
        viewModel.densitySyringePlusSugarVol = nil
        viewModel.densitySyringeCleanGelatin = nil
        viewModel.densitySyringePlusGelatinMass = nil
        viewModel.densitySyringePlusGelatinVol = nil
        viewModel.densitySyringeCleanActive = nil
        viewModel.densitySyringePlusActiveMass = nil
        viewModel.densitySyringePlusActiveVol = nil
        viewModel.additionalMeasurements = [
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 1"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 2"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 3"),
            BatchConfigViewModel.AdditionalMeasurement(label: "Container 4"),
        ]
        viewModel.additionalMeasurementsLocked = false

        // HP mode
        viewModel.highPrecisionMode = true
        viewModel.hpGlucoseSyrup = nil
        viewModel.hpActivationWater = nil
        viewModel.hpKSorbate = nil
        viewModel.hpFlavorOilsTerpsActive = nil
        viewModel.hpActivationTrayResidue = nil
        viewModel.hpSubstrateBeakerID = nil
        viewModel.hpSugarMixBeakerID = nil
        viewModel.hpActivationTrayID = nil
        viewModel.hpSubstrateScaleID = nil
        viewModel.hpSugarMixScaleID = nil
        viewModel.hpActivationScaleID = nil
        viewModel.hpSubstrateSugarTransfer = nil
        viewModel.hpSubstrateActivationTransfer = nil
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
        if potassiumSorbatePercent != 0.096 { return true }
        if citricAcidPercent != 0.786 { return true }
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
                molds.append(["shape": shape.rawValue, "count": def.count, "volumeML": def.volumeML])
            }
        }
        return [
            "moldSpecs": molds,
            "glucoseToSugarMassRatio": 1.000,
            "waterToGelatinMassRatio": 3.000,
            "waterMassPercentInSugarMix": 17.34,
            "potassiumSorbatePercent": 0.096,
            "citricAcidPercent": 0.786,
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
            "lsdTransferWaterML": 1.000,
            "defaultLsdUgPerTab": 117.0,
            "sugarMixtureOveragePercent": 5.0,
            "additivesInputAsMassPercent": false,
            "sliderVibrationsEnabled": true,
            "sliderResolution": 5.0,
            "doubleVisionEnabled": true,
            "doubleVisionIntensity": 2.0,
            "doubleVisionFadeTime": 0.6,
            "doubleVisionTrailCount": 10,
            "numericInputMode": "auto",
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
            "lsdTransferWaterML", "defaultLsdUgPerTab", "sugarMixtureOveragePercent",
            "resolutionBeakerEmpty", "resolutionBeakerPlusGelatin",
            "resolutionBeakerPlusSugar", "resolutionBeakerPlusActive",
            "resolutionBeakerResidue", "resolutionSyringeEmpty",
            "resolutionSyringeWithMix", "resolutionSyringeResidue",
            "resolutionMoldsFilled",
            "sliderResolution",
            "doubleVisionIntensity",
            "doubleVisionFadeTime",
        ]
        for key in doubleKeys {
            let curVal = current[key] as? Double ?? 0
            let refVal = ref[key] as? Double ?? 0
            if curVal != refVal { return false }
        }

        // Compare Bool values
        let boolKeys = ["additivesInputAsMassPercent", "sliderVibrationsEnabled", "isDarkMode", "doubleVisionEnabled"]
        for key in boolKeys {
            let curVal = current[key] as? Bool ?? false
            let refVal = ref[key] as? Bool ?? false
            if curVal != refVal { return false }
        }

        // Compare Int values
        let intKeys = ["doubleVisionTrailCount"]
        for key in intKeys {
            let curVal = current[key] as? Int ?? 0
            let refVal = ref[key] as? Int ?? 0
            if curVal != refVal { return false }
        }

        // Compare String values
        let stringKeys = ["numericInputMode"]
        for key in stringKeys {
            let curVal = current[key] as? String ?? ""
            let refVal = ref[key] as? String ?? ""
            if curVal != refVal { return false }
        }

        // Compare mold specs
        if let curMolds = current["moldSpecs"] as? [[String: Any]],
           let refMolds = ref["moldSpecs"] as? [[String: Any]] {
            if curMolds.count != refMolds.count { return false }
            for (cm, rm) in zip(curMolds, refMolds) {
                if (cm["shape"] as? String) != (rm["shape"] as? String) { return false }
                if (cm["count"] as? Int) != (rm["count"] as? Int) { return false }
                if (cm["volumeML"] as? Double) != (rm["volumeML"] as? Double) { return false }
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
            molds.append(["shape": shape.rawValue, "count": s.count, "volumeML": s.volumeML])
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
            "lsdTransferWaterML": lsdTransferWaterML,
            "defaultLsdUgPerTab": defaultLsdUgPerTab,
            "sugarMixtureOveragePercent": sugarMixtureOveragePercent,
            "additivesInputAsMassPercent": additivesInputAsMassPercent,
            "sliderVibrationsEnabled": sliderVibrationsEnabled,
            "sliderResolution": sliderResolution,
            "doubleVisionEnabled": doubleVisionEnabled,
            "doubleVisionIntensity": doubleVisionIntensity,
            "doubleVisionFadeTime": doubleVisionFadeTime,
            "doubleVisionTrailCount": doubleVisionTrailCount,
            "numericInputMode": numericInputMode.rawValue,
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
                if let vol = m["volumeML"] as? Double { s.volumeML = vol }
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
        if let v = json["lsdTransferWaterML"] as? Double { lsdTransferWaterML = v }
        if let v = json["defaultLsdUgPerTab"] as? Double { defaultLsdUgPerTab = v }
        if let v = json["sugarMixtureOveragePercent"] as? Double { sugarMixtureOveragePercent = v }
        if let v = json["additivesInputAsMassPercent"] as? Bool { additivesInputAsMassPercent = v }
        if let v = json["sliderVibrationsEnabled"] as? Bool { sliderVibrationsEnabled = v }
        if let v = json["sliderResolution"] as? Double { sliderResolution = v }
        if let v = json["doubleVisionEnabled"] as? Bool { doubleVisionEnabled = v }
        if let v = json["doubleVisionIntensity"] as? Double { doubleVisionIntensity = v }
        if let v = json["doubleVisionFadeTime"] as? Double { doubleVisionFadeTime = v }
        if let v = json["doubleVisionTrailCount"] as? Int { doubleVisionTrailCount = v }
        // Migrate legacy property name
        if let v = json["chromaticAberrationEnabled"] as? Bool { doubleVisionEnabled = v }
        if let v = json["numericInputMode"] as? String,
           let mode = NumericInputMode(rawValue: v) { numericInputMode = mode }
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
        lsdTransferWaterML = 1.000

        // Default µg / tab
        defaultLsdUgPerTab = 117.0

        // Mixture overage
        sugarMixtureOveragePercent = 5.0

        // Additives
        potassiumSorbatePercent = 0.096
        citricAcidPercent = 0.786
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

        // Laboratory scales
        scales = Self.factoryScales
        defaultScaleOverrides = [:]

        // Haptics
        sliderVibrationsEnabled = true

        // Slider Resolution
        sliderResolution = 5.0

        // Double vision ghost trail
        doubleVisionEnabled = true
        doubleVisionIntensity = 2.0
        doubleVisionFadeTime = 0.6
        doubleVisionTrailCount = 10

        // Numeric input
        numericInputMode = .auto

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
