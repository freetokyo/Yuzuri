import SwiftUI
import YuzuriKit

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(TemplateStore.self) private var templateStore
    @State private var showPaywall = false
    @State private var selectedLocale = LocaleResolver.resolve()

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("購入") {
                    if store.isUnlocked {
                        Label("プレミアム解放済み", systemImage: "checkmark.seal")
                    } else {
                        Button("プレミアムを解放") { showPaywall = true }
                    }
                    Button("購入を復元") { Task { await store.restore() } }
                }

                Section("表示言語") {
                    Picker("言語", selection: $selectedLocale) {
                        Text("日本語").tag("ja")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedLocale) { _, lang in
                        templateStore.load(localeOverride: lang)
                    }
                }

                Section("バックアップ") {
                    NavigationLink("暗号化バックアップ") {
                        ArchiveView()
                            .environment(store)
                    }
                }

                Section("情報") {
                    Link("利用規約", destination: AppLinks.terms)
                    Link("プライバシーポリシー", destination: AppLinks.privacy)
                    Link("サポート", destination: AppLinks.support)
                    LabeledContent("バージョン", value: versionString)
                }

                #if DEBUG
                Section("Debug") {
                    Button("Force unlock toggle") { store.debugToggleUnlock() }
                }
                #endif
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
        }
    }
}
