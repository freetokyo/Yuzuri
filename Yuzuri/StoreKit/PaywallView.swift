import SwiftUI

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text(LocalizedStringKey("paywall.title"))
                .font(.title.bold())
            Text(LocalizedStringKey("paywall.subtitle"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await store.purchase() }
            } label: {
                if let product = store.product {
                    Text(String(format: NSLocalizedString("paywall.unlockButton", comment: ""),
                                product.displayPrice))
                        .frame(maxWidth: .infinity)
                } else {
                    Text(LocalizedStringKey("paywall.unlockFallback"))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.product == nil)

            Button(LocalizedStringKey("paywall.restore")) { Task { await store.restore() } }

            // 利用規約 / プライバシーのリンクは必須（審査 3.1.2 対策）
            HStack(spacing: 16) {
                Link(LocalizedStringKey("paywall.terms"),   destination: AppLinks.terms)
                Link(LocalizedStringKey("paywall.privacy"), destination: AppLinks.privacy)
            }
            .font(.footnote)
        }
        .padding()
        .task { await store.load() }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }
}

#Preview {
    PaywallView().environment(EntitlementStore())
}
