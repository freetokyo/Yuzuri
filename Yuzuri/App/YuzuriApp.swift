import SwiftUI
import SwiftData
import YuzuriKit

@main
struct YuzuriApp: App {
    @State private var store = EntitlementStore()
    @State private var templateStore = TemplateStore()

    let container: ModelContainer = {
        let schema = Schema([NoteEntry.self, SensitiveBlob.self])
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
            RootTabView()
                .environment(store)
                .environment(templateStore)
                .task { await store.refresh() }
                .task { templateStore.load() }
        }
        .modelContainer(container)
    }
}
