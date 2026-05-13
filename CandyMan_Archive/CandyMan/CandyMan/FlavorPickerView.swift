import SwiftUI

struct FlavorPickerView: View {
    @Environment(BatchConfigViewModel.self) private var viewModel

    let adaptiveColumns = [GridItem(.adaptive(minimum: 110))]

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 8) {
            sectionHeader

            if viewModel.selectedFlavors.isEmpty {
                pickingView(viewModel: viewModel)
            } else if !viewModel.flavorsLocked {
                pickingView(viewModel: viewModel)
            } else {
                blendView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Text("Flavors").font(.headline)
            Spacer()
            Text(viewModel.flavorsLocked
                 ? "\(viewModel.selectedFlavors.count) selected"
                 : "\(viewModel.selectedFlavors.count) selected")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Picking State

    private func pickingView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 8) {
            Picker("Source", selection: $viewModel.flavorSourceTab) {
                ForEach(FlavorSourceType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                ForEach(currentFlavors) { flavor in
                    flavorTag(flavor: flavor, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)

            if viewModel.flavorSourceTab == .oils && terpeneCount > 0 {
                Text("+ \(terpeneCount) Terpene\(terpeneCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            } else if viewModel.flavorSourceTab == .terpenes && oilCount > 0 {
                Text("+ \(oilCount) Flavor Oil\(oilCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if !viewModel.selectedFlavors.isEmpty {
                Button {
                    viewModel.lockFlavors()
                } label: {
                    Label("Set Blend Ratios", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
        }
    }

    // MARK: - Blend Ratio State

    private func blendView(viewModel: BatchConfigViewModel) -> some View {
        @Bindable var viewModel = viewModel

        let terpenes = Array(viewModel.selectedFlavors.keys.filter {
            if case .terpene = $0 { return true }; return false
        })
        let oils = Array(viewModel.selectedFlavors.keys.filter {
            if case .oil = $0 { return true }; return false
        })
        let terpeneTotal = terpenes.reduce(0.0) { $0 + (viewModel.selectedFlavors[$1] ?? 0) }
        let oilTotal     = oils.reduce(0.0)     { $0 + (viewModel.selectedFlavors[$1] ?? 0) }

        return VStack(spacing: 0) {

            // ── TERPENES ──────────────────────────────
            if !terpenes.isEmpty {
                HStack {
                    Text("Terpene Volume").font(.headline)
                    Spacer()
                    Text("ppm").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.top, 12)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.0", value: $viewModel.terpeneVolumePPM,
                              format: .number.precision(.fractionLength(1...3)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).fixedSize()
                    Text("ppm").font(.system(size: 20)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

                ForEach(terpenes, id: \.id) { flavor in
                    VStack(spacing: 4) {
                        HStack {
                            Text(flavor.displayName).font(.subheadline)
                            Spacer()
                            Text("\(viewModel.selectedFlavors[flavor] ?? 0, specifier: "%.0f")%")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { viewModel.selectedFlavors[flavor] ?? 0 },
                                set: { viewModel.selectedFlavors[flavor] = $0 }
                            ),
                            in: 0...100, step: 5
                        ).tint(.blue)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }

                HStack {
                    Text("Terpene blend").font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text("\(terpeneTotal, specifier: "%.0f")%")
                        .fontWeight(.semibold)
                        .foregroundStyle(abs(terpeneTotal - 100) < 0.5 ? .green : .red)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            if !terpenes.isEmpty && !oils.isEmpty {
                Divider().padding(.horizontal, 16).padding(.vertical, 4)
            }

            // ── FLAVOR OILS ───────────────────────────
            if !oils.isEmpty {
                HStack {
                    Text("Flavor Oil Volume").font(.headline)
                    Spacer()
                    Text("%").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.top, 12)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.0", value: $viewModel.flavorOilVolumePercent,
                              format: .number.precision(.fractionLength(1...3)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .bold)).fixedSize()
                    Text("%").font(.system(size: 20)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

                ForEach(oils, id: \.id) { flavor in
                    VStack(spacing: 4) {
                        HStack {
                            Text(flavor.displayName).font(.subheadline)
                            Spacer()
                            Text("\(viewModel.selectedFlavors[flavor] ?? 0, specifier: "%.0f")%")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { viewModel.selectedFlavors[flavor] ?? 0 },
                                set: { viewModel.selectedFlavors[flavor] = $0 }
                            ),
                            in: 0...100, step: 5
                        ).tint(.orange)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }

                HStack {
                    Text("Oil blend").font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Text("\(oilTotal, specifier: "%.0f")%")
                        .fontWeight(.semibold)
                        .foregroundStyle(abs(oilTotal - 100) < 0.5 ? .green : .red)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            Divider().padding(.horizontal, 16)

            // ── RE-PICK ───────────────────────────────
            Button {
                viewModel.unlockFlavors()
            } label: {
                Label("Re-pick Flavors", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }

    // MARK: - Tag Button

    @ViewBuilder
    private func flavorTag(flavor: FlavorSelection, viewModel: BatchConfigViewModel) -> some View {
        let isSelected = viewModel.isSelected(flavor)
        Button {
            viewModel.toggleFlavor(flavor)
        } label: {
            Text(flavor.displayName)
                .font(.caption).lineLimit(1)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var currentFlavors: [FlavorSelection] {
        switch viewModel.flavorSourceTab {
        case .terpenes: return TerpeneFlavor.allCases.map { .terpene($0) }
        case .oils:     return FlavorOil.allCases.map { .oil($0) }
        }
    }

    private var terpeneCount: Int {
        viewModel.selectedFlavors.keys.filter {
            if case .terpene = $0 { return true }; return false
        }.count
    }

    private var oilCount: Int {
        viewModel.selectedFlavors.keys.filter {
            if case .oil = $0 { return true }; return false
        }.count
    }
}
