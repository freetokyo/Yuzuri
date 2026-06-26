import SwiftUI

struct RootTabView: View {
    @Environment(EntitlementStore.self) private var store

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }
            ExportView()
                .tabItem { Label("書き出し", systemImage: "square.and.arrow.up") }
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootTabView()
        .environment(EntitlementStore())
        .environment(TemplateStore())
}
