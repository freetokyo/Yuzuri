import SwiftUI

struct RootTabView: View {
    @Environment(EntitlementStore.self) private var store

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(LocalizedStringKey("home.title"), systemImage: "house") }
            ExportView()
                .tabItem { Label(LocalizedStringKey("export.title"), systemImage: "square.and.arrow.up") }
            SettingsView()
                .tabItem { Label(LocalizedStringKey("settings.title"), systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootTabView()
        .environment(EntitlementStore())
        .environment(TemplateStore())
}
