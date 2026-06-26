import SwiftUI

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var store
    @State private var showPaywall = false

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"   // 「開発中」等の静的文字列を出さず Bundle から動的化
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
                Section("情報") {
                    Link("利用規約", destination: AppLinks.terms)
                    Link("プライバシーポリシー", destination: AppLinks.privacy)
                    Link("サポート", destination: AppLinks.support)
                    LabeledContent("バージョン", value: versionString)
                }
                #if DEBUG
                Section("Debug") {   // デバッグ専用 UI は必ず #if DEBUG でゲート
                    Button("Force unlock toggle") { store.debugToggleUnlock() }
                }
                #endif
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showPaywall) {
                // .sheet の中身は親の @Environment を継承しない → 明示再注入
                PaywallView().environment(store)
            }
        }
    }
}
