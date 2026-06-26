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
                    .task { await store.refresh() }
                    .task { templateStore.load() }

                if !didCompleteOnboarding {
                    OnboardingView(isPresented: $didCompleteOnboarding)
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
