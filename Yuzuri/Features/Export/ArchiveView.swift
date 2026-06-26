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
    @State private var importPassphrase = ""
    @State private var pendingImportURL: URL?

    var body: some View {
        Form {
            Section("書き出し（暗号化バックアップ）") {
                SecureField("パスフレーズ", text: $passphrase)
                SecureField("確認", text: $confirmPassphrase)

                Button {
                    Task { await exportArchive() }
                } label: {
                    Label("暗号化アーカイブを作成", systemImage: "archivebox")
                }
                .disabled(passphrase.isEmpty || passphrase != confirmPassphrase || isExporting)
            }

            Section("取り込み（復元）") {
                Button {
                    showImportPicker = true
                } label: {
                    Label("アーカイブファイルを選択", systemImage: "square.and.arrow.down")
                }
            }

            if let url = pendingImportURL {
                Section("パスフレーズを入力して復元") {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("パスフレーズ", text: $importPassphrase)
                    Button {
                        Task { await importArchive(url: url) }
                    } label: {
                        Label("復元する", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.orange)
                    }
                    .disabled(importPassphrase.isEmpty || isImporting)
                }
            }
        }
        .navigationTitle("バックアップ")
        .sheet(item: $shareItem) { item in ShareSheet(url: item.url) }
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
            let key = try CryptoManager.getOrCreateKey()
            let cats: [CategoryArchive] = entries.map { entry in
                let sensitive = entry.sensitive.map {
                    SensitiveEntry(fieldKey: $0.fieldKey, ciphertext: $0.ciphertext, nonce: $0.nonce)
                }
                return CategoryArchive(
                    categoryKey: entry.categoryKey,
                    structuredValues: entry.structuredValues,
                    freeText: entry.freeText,
                    userMarkedDone: entry.userMarkedDone,
                    updatedAt: entry.updatedAt,
                    sensitiveEntries: sensitive
                )
            }
            let payload = ArchivePayload(categories: cats)
            let data = try ArchiveManager.export(payload: payload, passphrase: passphrase)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ユズリバックアップ_\(formattedDate()).\(ArchiveManager.fileExtension)")
            try data.write(to: url)
            shareItem = ShareItem(url: url)
            _ = key // suppress warning
        } catch {
            alertMessage = "書き出しに失敗しました: \(error.localizedDescription)"
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

            // 既存エントリを全削除してインポート
            for existing in entries { ctx.delete(existing) }

            for cat in payload.categories {
                let entry = NoteEntry(categoryKey: cat.categoryKey)
                entry.structuredValues = cat.structuredValues
                entry.freeText = cat.freeText
                entry.userMarkedDone = cat.userMarkedDone
                entry.updatedAt = cat.updatedAt
                ctx.insert(entry)

                for s in cat.sensitiveEntries {
                    let blob = SensitiveBlob(fieldKey: s.fieldKey,
                                              ciphertext: s.ciphertext,
                                              nonce: s.nonce)
                    ctx.insert(blob)
                    entry.sensitive.append(blob)
                }
            }
            try ctx.save()
            pendingImportURL = nil
            importPassphrase = ""
            alertMessage = "復元が完了しました（\(payload.categories.count)件）"
            showAlert = true
        } catch {
            alertMessage = "復元に失敗しました。パスフレーズを確認してください。"
            showAlert = true
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: .now)
    }
}
