import SwiftUI
import SwiftData
import YuzuriKit

struct ExportView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(TemplateStore.self) private var templateStore
    @Environment(\.modelContext) private var ctx
    @Query private var entries: [NoteEntry]

    @State private var isGenerating = false
    @State private var shareItem: ShareItem?
    @State private var showPaywall = false
    @State private var includeEmpty = false
    @State private var ownerName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedStringKey("export.options")) {
                    TextField(LocalizedStringKey("export.ownerName"), text: $ownerName)
                    Toggle(LocalizedStringKey("export.includeEmpty"), isOn: $includeEmpty)
                }

                Section {
                    if store.isUnlocked {
                        Button {
                            generate(includeSensitive: false)
                        } label: {
                            Label(LocalizedStringKey("export.safe"), systemImage: "doc.text")
                        }
                        .disabled(isGenerating)

                        Button {
                            Task { await generateFull() }
                        } label: {
                            Label(LocalizedStringKey("export.full"), systemImage: "doc.text.fill")
                                .foregroundStyle(.orange)
                        }
                        .disabled(isGenerating)
                    } else {
                        Button { showPaywall = true } label: {
                            Label(LocalizedStringKey("export.premiumRequired"), systemImage: "lock.doc")
                        }
                    }
                } footer: {
                    Text(LocalizedStringKey("export.premiumFooter"))
                        .font(.caption)
                }

                if isGenerating {
                    Section {
                        HStack {
                            ProgressView()
                            Text(LocalizedStringKey("export.generating"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("export.title"))
            .sheet(item: $shareItem) { item in
                ShareSheet(url: item.url)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
        }
    }

    private func generate(includeSensitive: Bool, sensitiveValues: [String: [String: String]] = [:]) {
        isGenerating = true
        let categories = buildCategories(sensitiveValues: sensitiveValues)
        let opts = PDFOptions(
            includeSensitive: includeSensitive,
            includeEmpty: includeEmpty,
            ownerName: ownerName,
            locale: templateStore.locale,
            lastUpdated: .now
        )
        Task {
            let data = PDFGenerator.generate(categories: categories, options: opts)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ユズリ_\(formattedDate()).pdf")
            try? data.write(to: url)
            isGenerating = false
            shareItem = ShareItem(url: url)
        }
    }

    private func generateFull() async {
        let ok = await LockManager.shared.authenticate(
            reason: NSLocalizedString("lock.reason.fullExport", comment: ""))
        guard ok else { return }
        // 秘匿値を復号
        var sensitiveMap: [String: [String: String]] = [:]
        do {
            let key = try CryptoManager.getOrCreateKey()
            for entry in entries {
                var vals: [String: String] = [:]
                for blob in entry.sensitive {
                    if let data = try? CryptoManager.decrypt(ciphertext: blob.ciphertext, nonce: blob.nonce, using: key),
                       let str = String(data: data, encoding: .utf8) {
                        vals[blob.fieldKey] = str
                    }
                }
                sensitiveMap[entry.categoryKey] = vals
            }
        } catch {}
        generate(includeSensitive: true, sensitiveValues: sensitiveMap)
    }

    private func buildCategories(sensitiveValues: [String: [String: String]]) -> [PDFCategory] {
        let entryMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.categoryKey, $0) })
        return templateStore.categories.map { def in
            let entry = entryMap[def.categoryKey]
            return PDFCategory(
                def: def,
                structuredValues: entry?.structuredValues ?? [:],
                freeText: entry?.freeText ?? "",
                sensitiveValues: sensitiveValues[def.categoryKey] ?? [:]
            )
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: .now)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
