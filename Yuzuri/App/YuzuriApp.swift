import SwiftUI
import SwiftData
import YuzuriKit

@main
struct YuzuriApp: App {
    @State private var store = EntitlementStore()
    @State private var templateStore = TemplateStore()
    @State private var lockStore = LockGateStore()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer = {
        let schema = Schema([NoteEntry.self, SensitiveBlob.self, CustomField.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                    .environment(store)
                    .environment(templateStore)
                    .environment(lockStore)
                    .task { await store.load() }   // product eager 取得（Paywall 表示前に必須）
                    .task {
                    // -YuzuriLocale ja などの起動引数でスクショ用ロケール強制指定に対応
                    let args = CommandLine.arguments
                    let forced = args.firstIndex(of: "-YuzuriLocale").map { args[$0 + 1] }
                    templateStore.load(localeOverride: forced)
                }

                if !didCompleteOnboarding {
                    OnboardingView(didComplete: $didCompleteOnboarding)
                        .transition(.opacity)
                } else if lockStore.isLocked {
                    LockGateView(lockStore: lockStore)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: lockStore.isLocked)
            .onChange(of: scenePhase) { _, new in
                if new == .background { lockStore.lockOnBackground() }
            }
        }
        .modelContainer(container)
    }
}
