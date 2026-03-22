//
//  CandyManTests.swift
//  CandyManTests
//
//  Root test file — verifies test infrastructure works.
//

import Testing
@testable import CandyMan

struct CandyManTests {

    @Test func testFixturesCreateSuccessfully() {
        let config = TestFixtures.makeDefaultSystemConfig()
        let vm = TestFixtures.makeTropicalPunchViewModel()
        #expect(config.newBear.count == 35)
        #expect(vm.selectedShape == .newBear)
        #expect(vm.trayCount == 1)
        #expect(vm.activeConcentration == 10.0)
    }
}
