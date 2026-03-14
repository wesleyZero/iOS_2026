//
//  ShapePickerView.swift
//  CandyMan
//
//  Created by Wesley James on 3/13/26.
//

import Foundation
import SwiftUI

struct ShapePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    let columns = [
        GridItem(.flexible())
        ,GridItem(.flexible())
    ]

    var body : some View {
        @Bindable var viewModel = viewModel
        HStack {
            Text("Shape")
                .font(.headline)
            Spacer()
            Text("\(systemConfig.spec(for: viewModel.selectedShape).volume_ml, specifier: "%.2f") ml")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        VStack{
            // CHOOSE YOUR SHAPE
            shapeGrid

            // CHOOSE NUMBER OF TRAYS
            Stepper("Trays: \(viewModel.trayCount)", value: $viewModel.trayCount, in: 1...10)
                .padding(.horizontal, 24)

            // CHOOSE CONCENTRATION
            Stepper("Concentration: \(viewModel.activeConcentration, specifier: "%.1f") \(viewModel.units.rawValue)", value: $viewModel.activeConcentration, in: 0...1000, step: 5)
                .padding(.horizontal, 24)
        }
        .navigationTitle("Gummy Batch")
    }

    private var shapeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(GummyShape.allCases) { shape in
                shapeButton(for: shape)
            }
        }
        .padding(24)
    }

    private func shapeButton(for shape: GummyShape) -> some View {
        let isSelected = viewModel.selectedShape == shape
        return Button {
            viewModel.selectedShape = shape
        } label: {
            VStack {
                Image(systemName: shape.sfSymbol)
                Text(shape.rawValue)
            }
        }
        .foregroundStyle(isSelected ? Color.blue : Color.gray)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

}


