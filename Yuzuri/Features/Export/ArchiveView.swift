import SwiftUI
import SwiftData
import YuzuriKit

struct ArchiveView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.modelContext) private var ctx
    @Query private var entries: [NoteEntry]

    @State private var passphrase = ""
    @State private var confirmPassphrase = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showImportPicker = false
    @State private var shareItem: ShareItem?
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var showPaywall = false
    @State private var importPassphrase = ""
    @State private var pendingImportURL: URL?

    var body: some View {
        Form {
            if !store.isUnlocked {
                Section {
                    Button { showPaywall = true } label: {
                        Label(LocalizedStringKey("archive.premiumLabel"), systemImage: "lock.doc")
                    }
                }
            } else {
                Section(LocalizedStringKey("archive.exportSection")) {
                    SecureField(LocalizedStringKey("archive.passphraseField"), text: $passphrase)
                    SecureField(LocalizedStringKey("archive.confirmField"), text: $confirmPassphrase)
                    Button {
                        Task { await exportArchive() }
                    } label: {
                        Label(LocalizedStringKey("archive.exportButton"), systemImage: "archivebox")
                    }
                    .disabled(passphrase.isEmpty || passphrase != confirmPassphrase || isExporting)
                }

                Section(LocalizedStringKey("archive.importSection")) {
                    Button { showImportPicker = true } label: {
                        Label(LocalizedStringKey("archive.selectFile"), systemImage: "square.and.arrow.down")
                    }
                }

                if let url = pendingImportURL {
                    Section(LocalizedStringKey("archive.restoreSection")) {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField(LocalizedStringKey("archive.passphraseField"), text: $importPassphrase)
                        Button {
                            Task { await importArchive(url: url) }
                        } label: {
                            Label(LocalizedStringKey("archive.restoreButton"), systemImage: "arrow.counterclockwise")
                                .foregroundStyle(.orange)
                        }
                        .disabled(importPassphrase.isEmpty || isImporting)
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey("archive.title"))
        .sheet(item: $shareItem) { item in ShareSheet(url: item.url) }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(store)
        }
        .fileImporter(isPresented: $showImportPicker,
                      allowedContentTypes: [.data],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                pendingImportURL = url
            }
        }
        .alert("", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - Export

    private func exportArchive() async {
        isExporting = true
        defer { isExporting = false }
        do {
            let cats: [CategoryArchive] = entries.map { entry in
                let sensitive = entry.sensitive.map {
                    SensitiveEntry(fieldKey: $0.fieldKey, ciphertext: $0.ciphertext, nonce: $0.nonce)
                }
                return CategoryArchive(categoryKey: entry.categoryKey,
                                       structuredValues: entry.structuredValues,
                                       freeText: entry.freeText,
                                       userMarkedDone: entry.userMarkedDone,
                                       updatedAt: entry.updatedAt,
                                       sensitiveEntries: sensitive)
            }
            let data = try ArchiveManager.export(payload: ArchivePayload(categories: cats),
                                                 passphrase: passphrase)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("YuzuriBackup_\(formattedDate()).\(ArchiveManager.fileExtension)")
            try data.write(to: url)
            shareItem = ShareItem(url: url)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    // MARK: - Import

    private func importArchive(url: URL) async {
        isImporting = true
        defer { isImporting = false }
        do {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let payload = try ArchiveManager.import(data: data, passphrase: importPassphrase)
            var newEntries: [NoteEntry] = []
            var newBlobs: [SensitiveBlob] = []
            for cat in payload.categories {
                let entry = NoteEntry(categoryKey: cat.categoryKey)
                entry.structuredValues = cat.structuredValues
                entry.freeText = cat.freeText
                entry.userMarkedDone = cat.userMarkedDone
                entry.updatedAt = cat.updatedAt
                newEntries.append(entry)
                for s in cat.sensitiveEntries {
                    let blob = SensitiveBlob(fieldKey: s.fieldKey, ciphertext: s.ciphertext, nonce: s.nonce)
                    entry.sensitive.append(blob)
                    newBlobs.append(blob)
                }
            }
            for existing in entries { ctx.delete(existing) }
            for e in newEntries { ctx.insert(e) }
            for b in newBlobs { ctx.insert(b) }
            try ctx.save()
            pendingImportURL = nil
            importPassphrase = ""
            alertMessage = String(format: NSLocalizedString("archive.restoreComplete", comment: ""),
                                  newEntries.count)
            showAlert = true
        } catch {
            alertMessage = NSLocalizedString("archive.restoreFailed", comment: "")
            showAlert = true
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd"
        return f.string(from: .now)
    }
}
