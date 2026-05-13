//
//  ContentView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(SystemConfig.self) private var systemConfig
    @Query private var savedCarts: [SavedCart]

    var body: some View {
        NavigationStack {
            CartConfigView()
        }
        .onAppear {
            systemConfig.syncBatchIDCounter(from: savedCarts)
        }
    }
}

#Preview {
    ContentView()
        .environment(CartConfigViewModel())
        .environment(SystemConfig())
}
