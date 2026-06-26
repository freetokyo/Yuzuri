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

                Text("ユズリ")
                    .font(.largeTitle.bold())

                Text("プライベートな情報を守るため\n認証が必要です")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await lockStore.unlock() }
                } label: {
                    Label(lockStore.isAuthenticating ? "認証中…" : "ロックを解除",
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
