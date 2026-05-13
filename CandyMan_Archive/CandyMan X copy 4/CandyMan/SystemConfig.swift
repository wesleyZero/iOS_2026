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
        loadContainerTareWeights()
        loadContainers()
        loadScales()
        loadDefaultScaleOverrides()
        loadSavedDefaults()
        CMTheme.isDark = true
    }

    // MARK: Sugar Ratios

    /// Glucose syrup : granulated sugar by mass (1.0 = equal parts).
    var glucoseToSugarMassRatio: Double = 1.000

    var glucoseToSugarVolumeRatio: Double {
        glucoseToSugarMassRatio * (densitySucrose / densityGlucoseSyrup)
    }

    // MARK: Additives (volume % of total mix)

    var potassiumSorbatePercent: Double = 0.078
    var citricAcidPercent: Double = 0.638
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
        case title           = "Title"
        case primaryAccent   = "Primary Accent"
        case secondaryAccent = "Secondary Accent"
        case tertiaryAccent  = "Tertiary Accent"
        case scarlet         = "Scarlet"

        var id: String { rawValue }

        /// Factory default color for each role (as RGB).
        var factoryColor: Color {
            switch self {
            case .title:           return Color(red: 0.031, green: 0.514, blue: 0.584)  // Deep Current
            case .primaryAccent:   return Color(red: 0.929, green: 0.278, blue: 0.290)  // Strawberry Red
            case .secondaryAccent: return Color(red: 1.000, green: 0.000, blue: 0.529)  // Fuchsia Flare
            case .tertiaryAccent:  return Color(red: 0.920, green: 0.680, blue: 0.320)  // Amber Gold
            case .scarlet:         return Color(red: 0.753, green: 0.027, blue: 0.027)  // Scarlet
            }
        }

        /// Factory default HSB values.
        var factoryHSB: (h: Double, s: Double, b: Double) {
            switch self {
            case .title:           return (0.521, 0.947, 0.584)  // Deep Current
            case .primaryAccent:   return (0.003, 0.699, 0.929)  // Strawberry Red
            case .secondaryAccent: return (0.917, 1.000, 1.000)  // Fuchsia Flare
            case .tertiaryAccent:  return (0.100, 0.652, 0.920)  // Amber Gold
            case .scarlet:         return (0.000, 0.964, 0.753)  // Scarlet
            }
        }

        /// Description of what this color is used for.
        var usage: String {
            switch self {
            case .title:           return "Section titles & headers"
            case .primaryAccent:   return "Primary data highlights & warnings"
            case .secondaryAccent: return "Overage data & corrections"
            case .tertiaryAccent:  return "LSD transfer & secondary data"
            case .scarlet:         return "Error states & critical values"
            }
        }

        /// Preset color palette for this role — tappable swatches in the editor.
        var presets: [DesignColorPreset] {
            switch self {
            case .title:
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
            case .primaryAccent:
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
            case .secondaryAccent:
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
            case .tertiaryAccent:
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
            case .scarlet:
                return [
                    DesignColorPreset("Scarlet",        h: 0.000, s: 0.964, b: 0.753),
                    DesignColorPreset("Crimson Tide",   h: 0.980, s: 0.900, b: 0.700),
                    DesignColorPreset("Merlot",         h: 0.970, s: 0.800, b: 0.550),
                    DesignColorPreset("Dragon Fire",    h: 0.010, s: 0.950, b: 0.850),
                    DesignColorPreset("Garnet",         h: 0.990, s: 0.850, b: 0.600),
                    DesignColorPreset("Oxblood",        h: 0.000, s: 0.850, b: 0.450),
                    DesignColorPreset("Cinnabar",       h: 0.030, s: 0.900, b: 0.800),
                    DesignColorPreset("Pomegranate",    h: 0.975, s: 0.800, b: 0.700),
                    DesignColorPreset("Cherry Cola",    h: 0.985, s: 0.750, b: 0.500),
                    DesignColorPreset("Inferno",        h: 0.020, s: 1.000, b: 0.900),
                ]
            }
        }
    }

    /// A named preset color option within a design role palette.
    struct DesignColorPreset: Identifiable {
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

    /// A design theme — a named set of colors for all five design roles.
    struct DesignTheme: Identifiable {
        let id: String
        let name: String
        let title: DesignColorPreset
        let primary: DesignColorPreset
        let secondary: DesignColorPreset
        let tertiary: DesignColorPreset
        let scarlet: DesignColorPreset

        func color(for role: DesignColorRole) -> DesignColorPreset {
            switch role {
            case .title:           return title
            case .primaryAccent:   return primary
            case .secondaryAccent: return secondary
            case .tertiaryAccent:  return tertiary
            case .scarlet:         return scarlet
            }
        }
    }

    /// Built-in design themes.
    static let designThemes: [DesignTheme] = [
        DesignTheme(
            id: "factory", name: "Factory",
            title:     DesignColorPreset("Deep Current",   h: 0.521, s: 0.947, b: 0.584),
            primary:   DesignColorPreset("Strawberry Red", h: 0.003, s: 0.699, b: 0.929),
            secondary: DesignColorPreset("Fuchsia Flare",  h: 0.917, s: 1.000, b: 1.000),
            tertiary:  DesignColorPreset("Amber Gold",     h: 0.100, s: 0.652, b: 0.920),
            scarlet:   DesignColorPreset("Scarlet",        h: 0.000, s: 0.964, b: 0.753)
        ),
        DesignTheme(
            id: "midnight", name: "Midnight",
            title:     DesignColorPreset("Ocean Abyss",    h: 0.580, s: 0.800, b: 0.500),
            primary:   DesignColorPreset("Neon Rose",      h: 0.950, s: 0.800, b: 1.000),
            secondary: DesignColorPreset("Electric Orchid", h: 0.830, s: 0.750, b: 1.000),
            tertiary:  DesignColorPreset("Candlelight",    h: 0.140, s: 0.750, b: 1.000),
            scarlet:   DesignColorPreset("Dragon Fire",    h: 0.010, s: 0.950, b: 0.850)
        ),
        DesignTheme(
            id: "ember", name: "Ember",
            title:     DesignColorPreset("Driftwood",      h: 0.080, s: 0.250, b: 0.650),
            primary:   DesignColorPreset("Blood Orange",   h: 0.030, s: 0.900, b: 0.950),
            secondary: DesignColorPreset("Hot Magenta",    h: 0.900, s: 0.900, b: 0.950),
            tertiary:  DesignColorPreset("Saffron",        h: 0.120, s: 0.800, b: 0.950),
            scarlet:   DesignColorPreset("Cinnabar",       h: 0.030, s: 0.900, b: 0.800)
        ),
        DesignTheme(
            id: "arctic", name: "Arctic",
            title:     DesignColorPreset("Glacier Bay",    h: 0.540, s: 0.600, b: 0.750),
            primary:   DesignColorPreset("Cherry Blossom", h: 0.970, s: 0.500, b: 0.950),
            secondary: DesignColorPreset("Bubblegum",      h: 0.930, s: 0.500, b: 1.000),
            tertiary:  DesignColorPreset("Champagne",      h: 0.110, s: 0.350, b: 0.950),
            scarlet:   DesignColorPreset("Pomegranate",    h: 0.975, s: 0.800, b: 0.700)
        ),
        DesignTheme(
            id: "noir", name: "Noir",
            title:     DesignColorPreset("Steel Violet",   h: 0.750, s: 0.450, b: 0.550),
            primary:   DesignColorPreset("Ember Glow",     h: 0.040, s: 0.850, b: 0.900),
            secondary: DesignColorPreset("Plum Pulse",     h: 0.820, s: 0.600, b: 0.800),
            tertiary:  DesignColorPreset("Burnt Sienna",   h: 0.060, s: 0.700, b: 0.780),
            scarlet:   DesignColorPreset("Merlot",         h: 0.970, s: 0.800, b: 0.550)
        ),
        DesignTheme(
            id: "botanical", name: "Botanical",
            title:     DesignColorPreset("Jade Mist",      h: 0.450, s: 0.560, b: 0.827),
            primary:   DesignColorPreset("Coral Flame",    h: 0.020, s: 0.750, b: 0.950),
            secondary: DesignColorPreset("Peony",          h: 0.910, s: 0.450, b: 0.950),
            tertiary:  DesignColorPreset("Honey Glaze",    h: 0.110, s: 0.550, b: 0.950),
            scarlet:   DesignColorPreset("Garnet",         h: 0.990, s: 0.850, b: 0.600)
        ),
    ]

    /// Apply a design theme, setting all five roles at once.
    func applyDesignTheme(_ theme: DesignTheme) {
        for role in DesignColorRole.allCases {
            let preset = theme.color(for: role)
            setDesignColor(hue: preset.hue, saturation: preset.saturation, brightness: preset.brightness, for: role)
        }
    }

    /// Returns the ID of the currently active design theme, if all 5 roles match a built-in theme.
    /// Returns `nil` if no overrides (factory defaults) → matches "factory", or if custom.
    var activeDesignThemeID: String? {
        // If no overrides at all, the Factory theme is effectively active
        if designColorOverrides.isEmpty { return "factory" }
        for theme in Self.designThemes {
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
    var designTitle: Color { designColor(for: .title) }
    var designPrimaryAccent: Color { designColor(for: .primaryAccent) }
    var designSecondaryAccent: Color { designColor(for: .secondaryAccent) }
    var designTertiaryAccent: Color { designColor(for: .tertiaryAccent) }
    var designScarlet: Color { designColor(for: .scarlet) }

    private static let designColorOverridesKey = "designColorOverrides"

    private func saveDesignColorOverrides() {
        if let data = try? JSONEncoder().encode(designColorOverrides) {
            UserDefaults.standard.set(data, forKey: Self.designColorOverridesKey)
        }
    }

    private func loadDesignColorOverrides() {
        if let data = UserDefaults.standard.data(forKey: Self.designColorOverridesKey),
           let overrides = try? JSONDecoder().decode([String: DesignColorOverride].self, from: data) {
            designColorOverrides = overrides
        }
    }

    // MARK: - Appearance Mode
    /// Dark mode is always on. Property kept for settings export/import compatibility.
    var isDarkMode: Bool = true

    // MARK: - Haptic Feedback
    var sliderVibrationsEnabled: Bool = true

    // MARK: - Developer Mode

    var developerMode: Bool = true
    var expandDetailSectionsByDefault: Bool = false
    var syntheticDataSet1Enabled: Bool = true
    var syntheticMeasurementsEnabled: Bool = true

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
        viewModel.prePopulateRecommendedScales(systemConfig: self)
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
        viewModel.extraGummyMixGrams = 1.847

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

        // Additional measurements (container residues)
        viewModel.additionalMeasurements = [
            BatchConfigViewModel.AdditionalMeasurement(label: "Funnel", initialMass: 52.310, finalMass: 52.847),
            BatchConfigViewModel.AdditionalMeasurement(label: "Spatula", initialMass: 31.205, finalMass: 31.418),
            BatchConfigViewModel.AdditionalMeasurement(label: "Pipette", initialMass: 8.112, finalMass: 8.237),
            BatchConfigViewModel.AdditionalMeasurement(label: "Bowl", initialMass: 145.620, finalMass: 146.103),
        ]

        // HP mode synthetic data
        viewModel.highPrecisionMode = true
        viewModel.hpSubstrateBeakerID = "Beaker 250ml"
        viewModel.hpSugarMixBeakerID = "Beaker 150ml"
        viewModel.hpActivationTrayID = "Beaker 50ml"
        viewModel.hpSubstrateScaleID = "B"   // Scale B: 0.01 g / 500 g
        viewModel.hpSugarMixScaleID  = "B"   // Scale B: 0.01 g / 500 g
        viewModel.hpActivationScaleID = "A"  // Scale A: 0.001 g / 100 g
        viewModel.hpGelatin = 21.045
        viewModel.hpGelatinWater = 63.135
        viewModel.hpGranulated = 75.200
        viewModel.hpGlucoseSyrup = 75.200
        viewModel.hpSugarWater = 31.420
        viewModel.hpCitricAcid = 0.845
        viewModel.hpActivationWater = 1.200
        viewModel.hpKSorbate = 0.112
        viewModel.hpFlavorOilsTerpsActive = 1.350
        viewModel.hpActivationTrayResidue = 0.185
        viewModel.hpSubstrateSugarTransfer = 365.800
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
        viewModel.highPrecisionMode = false
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
                molds.append(["shape": shape.rawValue, "count": def.count, "volumeML": def.volumeML])
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
            "lsdTransferWaterML": 1.000,
            "defaultLsdUgPerTab": 117.0,
            "sugarMixtureOveragePercent": 5.0,
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
            "lsdTransferWaterML", "defaultLsdUgPerTab", "sugarMixtureOveragePercent",
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

        // Laboratory scales
        scales = Self.factoryScales
        defaultScaleOverrides = [:]

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
