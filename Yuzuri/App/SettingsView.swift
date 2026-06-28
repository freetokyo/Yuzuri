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
                Section(LocalizedStringKey("settings.purchase")) {
                    if store.isUnlocked {
                        Label(LocalizedStringKey("settings.unlocked"), systemImage: "checkmark.seal")
                    } else {
                        Button(LocalizedStringKey("settings.unlock")) { showPaywall = true }
                    }
                    Button(LocalizedStringKey("settings.restore")) { Task { await store.restore() } }
                }

                Section(LocalizedStringKey("settings.language")) {
                    Picker(LocalizedStringKey("settings.language"), selection: $selectedLocale) {
                        Text("日本語").tag("ja")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedLocale) { _, lang in
                        templateStore.load(localeOverride: lang)
                    }
                }

                Section(LocalizedStringKey("settings.backup")) {
                    NavigationLink(LocalizedStringKey("archive.title")) {
                        ArchiveView()
                            .environment(store)
                    }
                }

                Section(LocalizedStringKey("settings.info")) {
                    Link(LocalizedStringKey("link.terms"),   destination: AppLinks.terms)
                    Link(LocalizedStringKey("link.privacy"), destination: AppLinks.privacy)
                    Link(LocalizedStringKey("link.support"), destination: AppLinks.support)
                    LabeledContent(LocalizedStringKey("settings.version"), value: versionString)
                }

                #if DEBUG
                Section("Debug") {
                    Button("Force unlock toggle") { store.debugToggleUnlock() }
                }
                #endif
            }
            .navigationTitle(LocalizedStringKey("settings.title"))
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
        }
    }
}
