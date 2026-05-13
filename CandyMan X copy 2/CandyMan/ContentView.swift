//
//  ContentView.swift
//  CandyMan
//
//  Root view that wraps ShapePickerView in a NavigationStack and syncs the
//  batch ID counter on appear. Injected into the scene by CandyManApp.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Query private var savedBatches: [SavedBatch]

    var body: some View {
        NavigationStack {
            ShapePickerView()
        }
        .onAppear {
            systemConfig.syncBatchIDCounter(from: savedBatches)
        }
    }
}

#Preview {
    ContentView()
        .environment(BatchConfigViewModel())
        .environment(SystemConfig())
}
