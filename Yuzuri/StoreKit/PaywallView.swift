import SwiftUI

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("プレミアムを解放")
                .font(.title.bold())
            Text("買い切り（サブスクなし）。一度購入すればずっと使えます。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await store.purchase() }
            } label: {
                Text(store.product.map { "\($0.displayPrice) で解放" } ?? "解放")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.product == nil)   // 商品未取得時は購入不可

            Button("購入を復元") { Task { await store.restore() } }

            // 利用規約 / プライバシーのリンクは必須（審査 3.1.2 対策）
            HStack(spacing: 16) {
                Link("利用規約", destination: AppLinks.terms)
                Link("プライバシー", destination: AppLinks.privacy)
            }
            .font(.footnote)
        }
        .padding()
        .task { await store.load() }          // 商品を eager 取得
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }
}

#Preview {
    PaywallView().environment(EntitlementStore())
}
