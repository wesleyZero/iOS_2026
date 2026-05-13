//
//  CartHistoryView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI
import SwiftData

struct CartHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedCart.date, order: .reverse) private var allCarts: [SavedCart]

    private var activeCarts: [SavedCart] { allCarts.filter { !$0.isTrashed } }
    private var trashedCarts: [SavedCart] { allCarts.filter { $0.isTrashed } }

    @State private var showTrash = false

    var body: some View {
        NavigationStack {
            List {
                if activeCarts.isEmpty {
                    ContentUnavailableView("No Saved Carts",
                        systemImage: "flame",
                        description: Text("Calculate and save a cart batch to see it here."))
                } else {
                    ForEach(activeCarts) { cart in
                        NavigationLink {
                            CartDetailView(cart: cart)
                        } label: {
                            cartRow(cart)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                cart.isTrashed = true
                                cart.trashedDate = .now
                            } label: {
                                Label("Trash", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CMTheme.pageBG)
            .navigationTitle("Cart History")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !trashedCarts.isEmpty {
                        Button {
                            showTrash = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(CMTheme.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showTrash) {
                TrashView(trashedCarts: trashedCarts)
            }
        }
    }

    private func cartRow(_ cart: SavedCart) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cart.batchID)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(CMTheme.textPrimary)
                Text(cart.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                Text(cart.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(CMTheme.textTertiary)
            }
            HStack(spacing: 12) {
                Label(cart.cartSizeRaw, systemImage: "battery.75percent")
                Label("×\(cart.cartCount)", systemImage: "number")
                Label(String(format: "%.0f%% weed", cart.weedComposition * 100), systemImage: "leaf")
            }
            .font(.caption)
            .foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.vertical, 4)
        .listRowBackground(CMTheme.cardBG)
    }
}

// MARK: - Trash View

struct TrashView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let trashedCarts: [SavedCart]

    var body: some View {
        NavigationStack {
            List {
                ForEach(trashedCarts) { cart in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(cart.batchID) \(cart.name)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CMTheme.textPrimary)
                            if let trashed = cart.trashedDate {
                                Text("Trashed \(trashed, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(CMTheme.textTertiary)
                            }
                        }
                        Spacer()
                        Button {
                            cart.isTrashed = false
                            cart.trashedDate = nil
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundStyle(CMTheme.success)
                        }
                        .buttonStyle(.plain)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(cart)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    .listRowBackground(CMTheme.cardBG)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CMTheme.pageBG)
            .navigationTitle("Trash")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Cart Detail View

struct CartDetailView: View {
    @Bindable var cart: SavedCart
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Summary card
                VStack(spacing: 0) {
                    HStack {
                        Text("Batch \(cart.batchID)")
                            .font(.headline)
                            .foregroundStyle(CMTheme.textPrimary)
                        Spacer()
                        Text(cart.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                    }
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                    detailRow("Name", value: cart.name)
                    detailRow("Cart Size", value: cart.cartSizeRaw)
                    detailRow("Cart Count", value: "\(cart.cartCount)")
                    detailRow("Weed %", value: String(format: "%.1f%%", cart.weedComposition * 100))
                    detailRow("Terp %", value: String(format: "%.1f%%", cart.terpComposition * 100))
                    if cart.baseComposition > 0 {
                        detailRow("Base %", value: String(format: "%.1f%%", cart.baseComposition * 100))
                    }
                    if cart.cutComposition > 0 {
                        detailRow("Cut %", value: String(format: "%.1f%%", cart.cutComposition * 100))
                    }

                    ThemedDivider()

                    detailRow("Total Volume", value: String(format: "%.4f ml", cart.totalOutput_mL))
                    detailRow("Weed Distillate", value: String(format: "%.4f ml", cart.weedDistillate_mL))
                    detailRow("Base", value: String(format: "%.4f ml", cart.base_mL))
                    detailRow("Cut", value: String(format: "%.4f ml", cart.cut_mL))
                    detailRow("Terpenes", value: String(format: "%.4f ml", cart.totalTerpenes_mL))

                    Spacer().frame(height: 8)
                }
                .cardStyle()

                // Terpenes card
                if !cart.terpenes.isEmpty {
                    VStack(spacing: 0) {
                        CMSectionHeader(title: "Terpene Breakdown")
                        ForEach(cart.terpenes) { terp in
                            detailRow(terp.name,
                                      value: String(format: "%.0f%% — %.4f ml", terp.percent, terp.volume_mL))
                        }
                        Spacer().frame(height: 8)
                    }
                    .cardStyle()
                }

                // Notes card
                VStack(spacing: 8) {
                    CMSectionHeader(title: "Notes")

                    if !cart.notesLocked {
                        TextField("Flavor notes...", text: $cart.flavorNotes, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundStyle(CMTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .cmFieldStyle()
                            .padding(.horizontal, 16)

                        TextField("Process notes...", text: $cart.processNotes, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundStyle(CMTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .cmFieldStyle()
                            .padding(.horizontal, 16)

                        // Star rating
                        HStack {
                            Text("Rating")
                                .font(.subheadline)
                                .foregroundStyle(CMTheme.textSecondary)
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    cart.flavorRating = star
                                } label: {
                                    Image(systemName: star <= cart.flavorRating ? "star.fill" : "star")
                                        .foregroundStyle(star <= cart.flavorRating ? .yellow : CMTheme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)

                        Button {
                            CMHaptic.medium()
                            cart.notesLocked = true
                        } label: {
                            Label("Lock Notes", systemImage: "lock")
                                .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                                .foregroundStyle(CMTheme.textPrimary)
                        }
                        .buttonStyle(CMPressStyle())
                        .padding(.horizontal, 16)
                    } else {
                        if !cart.flavorNotes.isEmpty {
                            Text(cart.flavorNotes)
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textSecondary)
                                .padding(.horizontal, 20)
                        }
                        if !cart.processNotes.isEmpty {
                            Text(cart.processNotes)
                                .font(.system(size: 14))
                                .foregroundStyle(CMTheme.textSecondary)
                                .padding(.horizontal, 20)
                        }
                        if cart.flavorRating > 0 {
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= cart.flavorRating ? "star.fill" : "star")
                                        .foregroundStyle(star <= cart.flavorRating ? .yellow : CMTheme.textTertiary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Button {
                            CMHaptic.light()
                            cart.notesLocked = false
                        } label: {
                            Label("Edit Notes", systemImage: "pencil")
                                .modifier(CMButtonStyle(color: CMTheme.chipBG, isDisabled: false))
                                .foregroundStyle(CMTheme.textPrimary)
                        }
                        .buttonStyle(CMPressStyle())
                        .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 8)
                }
                .cardStyle()
            }
            .padding(.vertical, 12)
        }
        .background(CMTheme.pageBG)
        .navigationTitle(cart.name)
        .preferredColorScheme(.dark)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(CMTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
    }
}
