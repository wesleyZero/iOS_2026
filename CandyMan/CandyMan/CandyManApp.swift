//
//  CandyManApp.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI

@main
struct CandyManApp: App {
    @State private var viewModel = BatchConfigViewModel()
    @State private var systemConfig = SystemConfig()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(systemConfig)
        }
    }
}
