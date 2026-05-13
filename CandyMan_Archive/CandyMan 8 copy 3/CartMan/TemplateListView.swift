//
//  TemplateListView.swift
//  CartMan
//
//  Created by Wesley James on 3/16/26.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CartConfigViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CartTemplate.createdDate, order: .reverse) private var templates: [CartTemplate]

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView("No Templates",
                        systemImage: "doc.on.doc",
                        description: Text("Save a cart configuration as a template to reuse it later."))
                } else {
                    ForEach(templates) { template in
                        Button {
                            CMHaptic.medium()
                            viewModel.applyTemplate(template)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(CMTheme.textPrimary)
                                HStack(spacing: 12) {
                                    Label(template.cartSizeRaw, systemImage: "battery.75percent")
                                    Label("×\(template.cartCount)", systemImage: "number")
                                    Label(String(format: "%.0f%% weed", template.weedComposition * 100), systemImage: "leaf")
                                    Label(String(format: "%.0f%% terp", template.terpComposition * 100), systemImage: "drop")
                                }
                                .font(.caption)
                                .foregroundStyle(CMTheme.textSecondary)

                                if !template.terpenes.isEmpty {
                                    Text(template.terpenes.map { t in
                                        if let sel = TerpeneSelection.fromID(t.terpeneID) {
                                            return sel.displayName
                                        }
                                        return t.terpeneID
                                    }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(CMTheme.textTertiary)
                                    .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(CMTheme.cardBG)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CMTheme.pageBG)
            .navigationTitle("Templates")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
