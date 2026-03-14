//
//  ContentView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ShapePickerView()
        }
    }
}

#Preview {
    ContentView()
        .environment(BatchConfigViewModel())
        .environment(SystemConfig())
}
