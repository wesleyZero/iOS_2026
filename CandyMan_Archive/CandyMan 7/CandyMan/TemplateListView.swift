import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Query(sort: \BatchTemplate.createdDate, order: .reverse) private var templates: [BatchTemplate]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.on.doc",
                        description: Text("Save a template from the Calculate Batch section.")
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            templateRow(template)
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("Templates")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func templateRow(_ template: BatchTemplate) -> some View {
        let isActive = viewModel.activeTemplateID == template.persistentModelID
        return Button {
            CMHaptic.medium()
            withAnimation(.cmSpring) {
                viewModel.applyTemplate(template)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(CMTheme.textPrimary)
                    Text(templateSummary(template))
                        .font(.caption)
                        .foregroundStyle(CMTheme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .foregroundStyle(CMTheme.strawberryRed)
                        .font(.system(size: 16, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func templateSummary(_ t: BatchTemplate) -> String {
        let shape = t.shape
        let active = t.activeName
        let conc = String(format: "%.1f %@", t.activeConcentration, t.activeUnit)
        let trays = "\(t.trayCount) tray\(t.trayCount == 1 ? "" : "s")"
        return "\(shape) · \(active) · \(conc) · \(trays)"
    }

    private func deleteTemplates(at offsets: IndexSet) {
        CMHaptic.medium()
        for index in offsets {
            let template = templates[index]
            if viewModel.activeTemplateID == template.persistentModelID {
                viewModel.activeTemplateID = nil
            }
            modelContext.delete(template)
        }
    }
}
