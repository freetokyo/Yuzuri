import SwiftUI

struct LockGateView: View {
    @Bindable var lockStore: LockGateStore

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)

                Text(LocalizedStringKey("app.name"))
                    .font(.largeTitle.bold())

                Text(LocalizedStringKey("lock.description"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await lockStore.unlock() }
                } label: {
                    Label(lockStore.isAuthenticating
                          ? LocalizedStringKey("lock.unlocking")
                          : LocalizedStringKey("lock.unlock"),
                          systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(lockStore.isAuthenticating)
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .task { await lockStore.unlock() }
    }
}
