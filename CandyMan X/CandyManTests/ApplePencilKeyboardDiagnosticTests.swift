//
//  ApplePencilKeyboardDiagnosticTests.swift
//  CandyManTests
//
//  Diagnostic tests for the Apple Pencil keyboard dismissal bug.
//  These tests simulate what happens when a single field is edited
//  and check whether the @Observable view model triggers cascading
//  recomputations that could cause SwiftUI to lose focus state.
//
//  HOW TO USE:
//  1. Run these tests from Xcode (Cmd+U or Product > Test)
//  2. Open the Console output (View > Debug Area > Activate Console)
//  3. Copy/paste the printed output back to Claude for analysis
//

import Testing
import Foundation
import Observation
@testable import CandyMan

// MARK: - Diagnostic: Observation Tracking

@Suite("Apple Pencil Keyboard Dismissal Diagnostics")
struct ApplePencilKeyboardDiagnosticTests {

    // MARK: Test 1 — Track which properties trigger observation when ONE field changes

    @Test("Diagnose: Single field mutation observation cascade")
    func diagnoseSingleFieldMutationCascade() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.batchCalculated = true
        let config = TestFixtures.makeDefaultSystemConfig()

        print("========================================")
        print("DIAGNOSTIC: Single Field Mutation Cascade")
        print("========================================")
        print("")

        // Simulate: user is typing into weightBeakerEmpty (the first measurement field)
        // Track what gets read during a typical view body evaluation

        print("--- BEFORE mutation ---")
        print("  weightBeakerEmpty: \(String(describing: vm.weightBeakerEmpty))")
        print("  weightBeakerPlusGelatin: \(String(describing: vm.weightBeakerPlusGelatin))")
        print("  highPrecisionMode: \(vm.highPrecisionMode)")
        print("  measurementsLocked: \(vm.measurementsLocked)")
        print("")

        // Mutate a single field (simulates user typing "9" into Syringe Clean field)
        print("--- MUTATING weightBeakerEmpty from nil -> 9.0 ---")
        vm.weightBeakerEmpty = 9.0

        print("  weightBeakerEmpty: \(String(describing: vm.weightBeakerEmpty))")
        print("")

        // Now check: does this mutation cause computed properties to change?
        print("--- Computed properties after mutation ---")
        print("  calcMassGelatinAdded: \(String(describing: vm.calcMassGelatinAdded))")
        print("  calcMassSugarAdded: \(String(describing: vm.calcMassSugarAdded))")
        print("  calcMassActiveAdded: \(String(describing: vm.calcMassActiveAdded))")
        print("  calcMassFinalMixtureInBeaker: \(String(describing: vm.calcMassFinalMixtureInBeaker))")
        print("  calcMassBeakerResidue: \(String(describing: vm.calcMassBeakerResidue))")
        print("")

        // Mutate again (simulates user typing second digit "9" -> text becomes "9")
        print("--- MUTATING weightBeakerEmpty from 9.0 -> nil (text cleared) ---")
        vm.weightBeakerEmpty = nil

        print("  weightBeakerEmpty: \(String(describing: vm.weightBeakerEmpty))")
        print("  calcMassGelatinAdded: \(String(describing: vm.calcMassGelatinAdded))")
        print("")

        print("========================================")
        print("END: Single Field Mutation Cascade")
        print("========================================")
    }

    // MARK: Test 2 — Simulate the exact Apple Pencil typing sequence

    @Test("Diagnose: Apple Pencil typing sequence simulation")
    func diagnoseApplePencilTypingSequence() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.batchCalculated = true

        print("")
        print("========================================")
        print("DIAGNOSTIC: Apple Pencil Typing Sequence")
        print("========================================")
        print("")
        print("This simulates what happens when the user taps '9' on the")
        print("numeric keypad using Apple Pencil while editing a field.")
        print("")
        print("The OptionalNumericField works like this:")
        print("  1. User taps field -> isFocused = true")
        print("  2. onChange(of: isFocused) fires -> sets text to editing format")
        print("  3. User types a digit -> text changes (e.g. '' -> '9')")
        print("  4. Text change does NOT immediately write to value binding")
        print("  5. Value only commits on focus LOSS")
        print("")
        print("POTENTIAL BUG SCENARIOS:")
        print("")

        // Scenario A: Does the text -> value -> text feedback loop cause issues?
        print("--- Scenario A: Text-Value feedback loop ---")
        print("  Initial value: \(String(describing: vm.densitySyringeCleanSugar))")

        // Simulate: field gains focus, text set to "" (value is nil)
        // User types "9" -> text = "9"
        // Does anything in the viewModel change that would trigger a re-render?

        // The key insight: OptionalNumericField only writes value on focus LOSS.
        // But if ANYTHING else in the @Observable viewModel changes while typing,
        // SwiftUI may re-evaluate the parent view body, and if the field's
        // identity changes (e.g., due to conditional logic or ForEach),
        // the @FocusState will be reset.

        print("  ANALYSIS: OptionalNumericField correctly defers value writes")
        print("  until focus loss. The text buffer is @State (local), so typing")
        print("  alone should NOT trigger viewModel observation changes.")
        print("")

        // Scenario B: Does the parent view's body re-evaluation destroy the field?
        print("--- Scenario B: Parent view body re-evaluation ---")
        print("  The WeightMeasurementsView body contains:")
        print("    - @Environment(BatchConfigViewModel.self)")
        print("    - @Bindable var viewModel = viewModel (local in body)")
        print("    - if viewModel.highPrecisionMode { ... }")
        print("    - BatchCalculator.calculate() INSIDE the body (line 88)")
        print("")
        print("  CRITICAL: When highPrecisionMode is true, the body calls")
        print("  BatchCalculator.calculate() on EVERY re-render. This reads")
        print("  many viewModel properties, which registers observation")
        print("  dependencies on ALL of them.")
        print("")

        // Scenario C: The CalibrationMeasurementsView (from screenshots)
        print("--- Scenario C: CalibrationMeasurementsView specifics ---")
        print("  CalibrationMeasurementsView uses:")
        print("    - weightRow() which creates OptionalNumericField")
        print("    - Each field binds directly to viewModel via $viewModel.xxx")
        print("    - The @Bindable wrapper in body creates observation tracking")
        print("")

        // Scenario D: Apple Pencil UIKit interaction
        print("--- Scenario D: Apple Pencil + .scribbleDisabled() interaction ---")
        print("  .scribbleDisabled() is applied to all numeric fields.")
        print("  With Apple Pencil, UIKit's text input system behaves differently:")
        print("  - Pencil taps may trigger a UIKit hover/touch sequence")
        print("  - This can cause resignFirstResponder to fire momentarily")
        print("  - If the field resigns and immediately re-focuses, the")
        print("    onChange(of: isFocused) handler fires TWICE:")
        print("    1. focused=false -> commits value, updates text")  
        print("    2. focused=true -> sets editing format, selectAll")
        print("  - The value commit in step 1 writes to the @Observable VM")
        print("  - This triggers SwiftUI to re-evaluate parent views")
        print("  - If the view hierarchy changes (e.g., computed values update),")
        print("    the field may lose its identity and not regain focus")
        print("")

        print("========================================")
        print("LIKELY ROOT CAUSE ANALYSIS")
        print("========================================")
        print("")
        print("The most likely cause is ONE OR BOTH of:")
        print("")
        print("1. APPLE PENCIL FOCUS BOUNCE: When tapping with Apple Pencil,")
        print("   UIKit may briefly resign first responder before re-establishing")
        print("   it. The onChange(of: isFocused) fires with focused=false,")
        print("   which commits the partial value to the @Observable viewModel.")
        print("   This triggers a cascade of SwiftUI view re-evaluations.")
        print("   By the time UIKit tries to re-establish focus, the view")
        print("   hierarchy has been rebuilt and the original field no longer")
        print("   exists in the same identity.")
        print("")
        print("2. @OBSERVABLE OVER-OBSERVATION: The @Bindable property wrapper")
        print("   in the view body registers observation on ALL accessed")
        print("   properties. When any property changes (even unrelated ones),")
        print("   the entire view body re-evaluates. Combined with the")
        print("   BatchCalculator.calculate() call inside the body, this")
        print("   creates a heavy re-render that can cause focus loss.")
        print("")
        print("RECOMMENDED FIXES:")
        print("  A. Add debounce/guard to prevent focus-loss commit during")
        print("     rapid Apple Pencil input")
        print("  B. Use .id() to stabilize field identity across re-renders")
        print("  C. Move BatchCalculator.calculate() out of the view body")
        print("  D. Consider using @FocusState at the parent level to")
        print("     explicitly manage which field has focus")
        print("")
        print("========================================")
        print("END: Apple Pencil Typing Sequence")
        print("========================================")
    }

    // MARK: Test 3 — Verify the text buffer isolation

    @Test("Diagnose: OptionalNumericField text buffer isolation")
    func diagnoseTextBufferIsolation() {
        let vm = TestFixtures.makeTropicalPunchViewModel()
        vm.batchCalculated = true

        print("")
        print("========================================")
        print("DIAGNOSTIC: Text Buffer Isolation Check")
        print("========================================")
        print("")

        // Verify that typing into one field doesn't change the viewModel
        // until focus is lost

        print("Step 1: Initial state")
        print("  densitySyringeCleanSugar = \(String(describing: vm.densitySyringeCleanSugar))")
        print("")

        print("Step 2: Simulating what happens during Apple Pencil digit entry")
        print("  When user taps '9' on keypad:")
        print("  - TextField's $text binding updates: '' -> '9'")
        print("  - @State text is VIEW-LOCAL, not on the viewModel")
        print("  - viewModel.densitySyringeCleanSugar remains nil")
        print("  - NO @Observable notification should fire")
        print("")

        // But let's verify: does accessing a computed property cause issues?
        print("Step 3: Check if computed properties cause observation registration")

        // Access several computed properties to see if they return stable values
        let v1 = vm.calcMassGelatinAdded
        let v2 = vm.calcMassSugarAdded
        let v3 = vm.calcMassTotalLoss
        print("  calcMassGelatinAdded = \(String(describing: v1))")
        print("  calcMassSugarAdded = \(String(describing: v2))")
        print("  calcMassTotalLoss = \(String(describing: v3))")
        print("  (All nil because no measurements set — EXPECTED)")
        print("")

        // Now test: what if we set weightBeakerEmpty while "focused"
        print("Step 4: Simulate focus-loss value commit")
        print("  Setting weightBeakerEmpty = 65.358 (simulating focus loss commit)")
        vm.weightBeakerEmpty = 65.358
        print("  weightBeakerEmpty = \(String(describing: vm.weightBeakerEmpty))")
        print("  calcMassGelatinAdded = \(String(describing: vm.calcMassGelatinAdded))")
        print("  (Still nil because weightBeakerPlusGelatin not set — EXPECTED)")
        print("")

        print("Step 5: Check observation count after mutation")
        print("  After setting weightBeakerEmpty, the following views will re-render:")
        print("    - WeightMeasurementsView (observes viewModel)")
        print("    - CalibrationMeasurementsView (observes viewModel)")
        print("    - BatchOutputView (if it observes viewModel)")
        print("    - MeasurementCalculationsView (if visible)")
        print("  Each re-render rebuilds ALL OptionalNumericField instances")
        print("  in the expanded section.")
        print("")
        print("  KEY QUESTION: Do the rebuilt fields retain @FocusState?")
        print("  ANSWER: Only if their SwiftUI identity is STABLE.")
        print("  Since weightRow() creates fields inline (not in a ForEach),")
        print("  SwiftUI uses structural identity. This SHOULD be stable...")
        print("  UNLESS the conditional logic (if isExpanded, if highPrecisionMode)")
        print("  causes the branch to be re-evaluated.")
        print("")

        print("========================================")
        print("ADDITIONAL DIAGNOSTIC: Check .scribbleDisabled() behavior")
        print("========================================")
        print("")
        print("  .scribbleDisabled() tells iPadOS to not recognize Apple Pencil")
        print("  handwriting on this field. However, it may have a side effect:")
        print("  when the pencil taps the numeric keypad button, iPadOS may")
        print("  route the touch through a different UIKit responder chain")
        print("  than a finger tap would use.")
        print("")
        print("  Specifically, Apple Pencil taps on software keyboard keys")
        print("  may trigger UIIndirectScribbleInteraction delegate methods")
        print("  even when scribble is disabled, which can cause momentary")
        print("  focus changes.")
        print("")
        print("  EXPERIMENT: Try REMOVING .scribbleDisabled() from")
        print("  OptionalNumericField and test with Apple Pencil again.")
        print("  If the keyboard stays open, .scribbleDisabled() is the cause.")
        print("")

        print("========================================")
        print("SUMMARY OF DIAGNOSTIC FINDINGS")
        print("========================================")
        print("")
        print("Please copy everything above and paste it to Claude.")
        print("Also report:")
        print("  1. Does the bug happen in BOTH standard and high-precision mode?")
        print("  2. Does it happen on the FIRST digit or only on subsequent digits?")
        print("  3. Is the Calibration Measurements section expanded when it happens?")
        print("  4. What iPad model and iPadOS version are you using?")
        print("  5. Does tapping with your FINGER (not pencil) work correctly?")
        print("")
        print("========================================")
        print("END: All Diagnostics")
        print("========================================")
    }
}
