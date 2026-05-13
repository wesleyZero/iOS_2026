//
//  TemplateListView.swift
//  CandyMan
//
//  Modal list of saved BatchTemplate records and customer BatchRequest records.
//  Templates are shown at the top; requests appear below a divider. A paste
//  button in the toolbar lets the user import a batch config from the clipboard
//  as a new request with a customer name.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Query(sort: \BatchTemplate.createdDate, order: .reverse) private var templates: [BatchTemplate]
    @Query(sort: \BatchRequest.createdDate, order: .reverse) private var requests: [BatchRequest]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(BatchConfigViewModel.self) private var viewModel
    @Environment(SystemConfig.self) private var systemConfig

    @State private var showNamePrompt = false
    @State private var pendingJSON = ""
    @State private var pendingDTO: SavedBatchDTO? = nil
    @State private var pendingConfigDTO: BatchConfigDTO? = nil
    @State private var requesterName = ""
    @State private var showPasteError = false
    @State private var pasteErrorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Templates Section
                if !templates.isEmpty {
                    Section {
                        ForEach(templates) { template in
                            templateRow(template)
                        }
                        .onDelete(perform: deleteTemplates)
                    } header: {
                        Text("Templates")
                    }
                }

                // MARK: - Requests Section
                Section {
                    if requests.isEmpty {
                        Text("No requests yet. Paste a batch config to create one.")
                            .font(.caption)
                            .foregroundStyle(CMTheme.textTertiary)
                    } else {
                        ForEach(requests) { request in
                            requestRow(request)
                        }
                        .onDelete(perform: deleteRequests)
                    }
                } header: {
                    Text("Requests")
                }
            }
            .navigationTitle("Templates & Requests")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(systemConfig.designTitle)
                    }
                }
            }
            .alert("Name This Request", isPresented: $showNamePrompt) {
                TextField("Requester name", text: $requesterName)
                Button("Cancel", role: .cancel) {
                    requesterName = ""
                    pendingDTO = nil
                    pendingConfigDTO = nil
                    pendingJSON = ""
                }
                Button("Save") {
                    saveRequest()
                }
            } message: {
                if let dto = pendingDTO {
                    Text("\(dto.shape) · \(dto.activeName) \(String(format: "%.1f", dto.activeConcentration)) \(dto.activeUnit) · \(dto.wellCount) gummies")
                } else if let cfg = pendingConfigDTO {
                    Text("\(cfg.shape) · \(cfg.active) \(String(format: "%.1f", cfg.concentration)) \(cfg.concentrationUnit) · \(cfg.gummies) gummies")
                }
            }
            .alert("Paste Failed", isPresented: $showPasteError) {
                Button("OK") { }
            } message: {
                Text(pasteErrorMessage)
            }
        }
    }

    // MARK: - Template Row

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
                        .foregroundStyle(systemConfig.designAlert)
                        .font(.system(size: 16, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Request Row

    private func requestRow(_ request: BatchRequest) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(request.requesterName)
                    .font(.headline)
                    .foregroundStyle(CMTheme.textPrimary)
                Spacer()
                if request.isFulfilled {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(systemConfig.designAlert)
                        .font(.system(size: 14))
                } else {
                    Text("Pending")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(systemConfig.designTitle)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(systemConfig.designTitle.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            Text(requestSummary(request))
                .font(.caption)
                .foregroundStyle(CMTheme.textTertiary)
                .lineLimit(1)
            Text(request.createdDate.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption2)
                .foregroundStyle(CMTheme.textTertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button {
                CMHaptic.medium()
                withAnimation(.cmSpring) { request.isFulfilled.toggle() }
            } label: {
                Label(request.isFulfilled ? "Unfulfill" : "Fulfill",
                      systemImage: request.isFulfilled ? "arrow.uturn.backward" : "checkmark.seal")
            }
            .tint(systemConfig.designAlert)
        }
    }

    // MARK: - Summaries

    private func templateSummary(_ t: BatchTemplate) -> String {
        let shape = t.shape
        let active = t.activeName
        let conc = String(format: "%.1f %@", t.activeConcentration, t.activeUnit)
        let trays = "\(t.trayCount) tray\(t.trayCount == 1 ? "" : "s")"
        return "\(shape) · \(active) · \(conc) · \(trays)"
    }

    private func requestSummary(_ r: BatchRequest) -> String {
        let shape = r.shape
        let active = r.activeName
        let conc = String(format: "%.1f %@", r.activeConcentration, r.activeUnit)
        let gummies = "\(r.wellCount) gummies"
        var parts = ["\(shape)", "\(active)", conc, gummies]
        if !r.flavorSummary.isEmpty { parts.append(r.flavorSummary) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Delete Actions

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

    private func deleteRequests(at offsets: IndexSet) {
        CMHaptic.medium()
        for index in offsets {
            modelContext.delete(requests[index])
        }
    }

    // MARK: - Paste from Clipboard

    private func pasteFromClipboard() {
        guard let jsonString = CMClipboard.paste(), !jsonString.isEmpty else {
            pasteErrorMessage = "Your clipboard is empty. Copy a batch config JSON first."
            showPasteError = true
            return
        }
        guard let data = jsonString.data(using: .utf8) else {
            pasteErrorMessage = "Could not read clipboard contents as text."
            showPasteError = true
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try decoding as SavedBatchDTO (array or single), then as the lighter
        // BatchConfigDTO produced by InputSummaryView's copy button.
        if let dtos = try? decoder.decode([SavedBatchDTO].self, from: data), let first = dtos.first {
            pendingDTO = first
            pendingConfigDTO = nil
            pendingJSON = jsonString
            requesterName = ""
            showNamePrompt = true
        } else if let dto = try? decoder.decode(SavedBatchDTO.self, from: data) {
            pendingDTO = dto
            pendingConfigDTO = nil
            pendingJSON = jsonString
            requesterName = ""
            showNamePrompt = true
        } else if let cfg = try? decoder.decode(BatchConfigDTO.self, from: data) {
            pendingDTO = nil
            pendingConfigDTO = cfg
            pendingJSON = jsonString
            requesterName = ""
            showNamePrompt = true
        } else {
            pasteErrorMessage = "Could not parse the clipboard as a batch config. Make sure it's valid batch JSON."
            showPasteError = true
        }
    }

    private func saveRequest() {
        let name = requesterName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? "Unknown" : name

        let request: BatchRequest
        if let dto = pendingDTO {
            request = BatchRequest.from(dto: dto, requesterName: finalName, rawJSON: pendingJSON)
        } else if let cfg = pendingConfigDTO {
            request = BatchRequest.from(config: cfg, requesterName: finalName, rawJSON: pendingJSON)
        } else {
            return
        }

        modelContext.insert(request)
        CMHaptic.success()
        requesterName = ""
        pendingDTO = nil
        pendingConfigDTO = nil
        pendingJSON = ""
    }
}
