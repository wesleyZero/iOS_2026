import SwiftUI

struct ShapePickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 12) {
                chooseShape
                    .cardStyle()
                chooseTrays(viewModel: viewModel)
                    .cardStyle()
                chooseActive(viewModel: viewModel)
                    .cardStyle()
                chooseGelatin(viewModel: viewModel)
                    .cardStyle()
                FlavorPickerView()
                    .cardStyle()
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Gummy Batch")
        .background(Color(.systemGray4))
        .scrollDismissesKeyboard(.immediately) 
    }

    // MARK: - Gelatin

    private func chooseGelatin(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 4) {
            sectionHeader(
                title: "Gelatin",
                detail: String(format: "%.2f%%", viewModel.gelatinPercentage)
            )
            HStack {



                VStack(spacing: 2) {
                    TextField("0.0", value: $viewModel.gelatinPercentage,
                              format: .number.precision(.fractionLength(1...3)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold))
                        .frame(width: 80)

                }

                Text("%")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)    // ← grayed out


            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)


        }
    }

    // MARK: - Shape

    private var chooseShape: some View {
        VStack(spacing: 0) {
            sectionHeader(
                title: "Shape",
                detail: String(format: "%.3f ml / mold", systemConfig.spec(for: viewModel.selectedShape).volume_ml)
            )
            shapeGrid
        }
    }

    private var shapeGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(GummyShape.allCases) { shape in
                shapeButton(for: shape)
            }
        }
        .padding(12)
    }

    // MARK: - Trays

    private func chooseTrays(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        @Bindable var systemConfig = systemConfig


        return VStack(spacing: 4) {
            sectionHeader(
                title: "Trays",
                detail: "\(systemConfig.spec(for: viewModel.selectedShape).count) per tray"
            )
            HStack {
                // Minus button
                Button {
                    viewModel.trayCount = max(1, viewModel.trayCount - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.blue)
                }

                Spacer()

                // Count display
                Text("\(viewModel.trayCount)")
                    .font(.system(size: 20, weight: .bold))
                Text("Tray\(viewModel.trayCount == 1 ? "" : "s")")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)    // ← grayed out
                Spacer()

                // Plus button
                Button {
                    viewModel.trayCount = min(20, viewModel.trayCount + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Text("\(viewModel.trayCount) \(viewModel.selectedShape.rawValue.lowercased()) tray\(viewModel.trayCount == 1 ? "" : "s") = \(viewModel.trayCount * systemConfig.spec(for: viewModel.selectedShape).count) units")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }

    }

    // MARK: - Concentration

    private func chooseActive(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 8) {
            sectionHeader(
                title: "Actives",
                detail: "\(String(format: "%.1f", viewModel.activeConcentration)) \(viewModel.units.rawValue) \(viewModel.selectedActive.rawValue) / gummy"
            )

            chooseSubstance()
//            chooseUnits()
            chooseConc()
            Spacer()
        }
    }

    private func chooseConc() -> some View {

        @Bindable var viewModel = viewModel
           return VStack(spacing: 4) {
               HStack {
                   // Value display — tappable to show keyboard
                   VStack(spacing: 2) {
                       TextField("0.0 \(viewModel.units.rawValue)",
                                 value: $viewModel.activeConcentration,
                                 format: .number.precision(.fractionLength(1...6)))
                           .keyboardType(.decimalPad)
                           .multilineTextAlignment(.center)
                           .font(.system(size: 30, weight: .bold))
                           .frame(width: 120)


                   }


                   Text(viewModel.selectedActive.unit.rawValue)
                       .font(.system(size: 20, weight: .regular))
                       .foregroundStyle(.secondary)    // ← grayed out

               }
               .padding(.horizontal, 24)
               .padding(.vertical, 12)


           }

    }

    private func chooseUnits() -> some View {
        @Bindable var viewModel = viewModel
        return HStack {
            Picker("Units", selection: $viewModel.units) {
                ForEach(ConcentrationUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }

    private func chooseSubstance() -> some View {
        @Bindable var viewModel = viewModel
        return HStack {

            Picker("Substance", selection: $viewModel.selectedActive) {
                ForEach(Active.allCases) { substance in
                    Text(substance.rawValue).tag(substance)
                }
            }

        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

    // MARK: - Reusable

    private func sectionHeader(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func shapeButton(for shape: GummyShape) -> some View {
        let isSelected = viewModel.selectedShape == shape
        return Button {
            viewModel.selectedShape = shape
        } label: {
            VStack(spacing: 8) {
                Image(systemName: shape.sfSymbol)
                    .font(.system(size: 28))
                Text(shape.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(isSelected ? .blue : .gray)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
