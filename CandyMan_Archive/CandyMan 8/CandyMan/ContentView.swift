//
//  ContentView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
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
