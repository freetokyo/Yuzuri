import SwiftUI

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── ヘッダー ────────────────────────────────────
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 32)

                    Text(LocalizedStringKey("paywall.compareTitle"))
                        .font(.title2.bold())

                    Text(LocalizedStringKey("paywall.noSubscription"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)

                // ── 比較テーブル ─────────────────────────────────
                VStack(spacing: 0) {

                    // 列ヘッダー
                    HStack {
                        Spacer()
                        PlanHeader(
                            title: LocalizedStringKey("paywall.free"),
                            tag: LocalizedStringKey("paywall.freeTag"),
                            isFree: true
                        )
                        PlanHeader(
                            title: LocalizedStringKey("paywall.premium"),
                            tag: LocalizedStringKey("paywall.premiumTag"),
                            isFree: false
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    Divider()

                    // 無料機能
                    SectionHeader(title: LocalizedStringKey("paywall.free"))

                    ForEach([
                        "paywall.free.1",
                        "paywall.free.2",
                        "paywall.free.3",
                        "paywall.free.4",
                    ], id: \.self) { key in
                        FeatureRow(
                            label: LocalizedStringKey(key),
                            freeHas: true,
                            premiumHas: true
                        )
                    }

                    // プレミアム機能
                    SectionHeader(title: LocalizedStringKey("paywall.premium"))

                    ForEach([
                        "paywall.premium.1",
                        "paywall.premium.2",
                        "paywall.premium.3",
                        "paywall.premium.4",
                        "paywall.premium.5",
                    ], id: \.self) { key in
                        FeatureRow(
                            label: LocalizedStringKey(key),
                            freeHas: false,
                            premiumHas: true
                        )
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                // ── 購入ボタン ────────────────────────────────────
                VStack(spacing: 12) {
                    Button {
                        Task { await store.purchase() }
                    } label: {
                        Group {
                            if let product = store.product {
                                Text(String(format: NSLocalizedString("paywall.unlockButton", comment: ""),
                                            product.displayPrice))
                            } else {
                                Text(LocalizedStringKey("paywall.unlockFallback"))
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(store.product == nil)

                    Button(LocalizedStringKey("paywall.restore")) {
                        Task { await store.restore() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // 審査 3.1.2: 利用規約・プライバシーリンク必須
                    HStack(spacing: 20) {
                        Link(LocalizedStringKey("paywall.terms"),   destination: AppLinks.terms)
                        Link(LocalizedStringKey("paywall.privacy"), destination: AppLinks.privacy)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .task { await store.load() }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }
}

// MARK: - Sub-views

private struct PlanHeader: View {
    let title: LocalizedStringKey
    let tag: LocalizedStringKey
    let isFree: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(isFree ? .secondary : Color.accentColor)
            Text(tag)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    isFree ? Color(.secondarySystemBackground) : Color.accentColor.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(isFree ? .secondary : Color.accentColor)
        }
        .frame(width: 110)
    }
}

private struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }
}

private struct FeatureRow: View {
    let label: LocalizedStringKey
    let freeHas: Bool
    let premiumHas: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.vertical, 12)

            CheckCell(has: freeHas, isPremium: false)
            CheckCell(has: premiumHas, isPremium: true)
        }
        Divider().padding(.leading, 16)
    }
}

private struct CheckCell: View {
    let has: Bool
    let isPremium: Bool

    var body: some View {
        Group {
            if has {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(isPremium ? Color.accentColor : .green)
            } else {
                Image(systemName: "minus")
                    .foregroundStyle(.quaternary)
            }
        }
        .font(.body)
        .frame(width: 110)
        .padding(.vertical, 12)
    }
}

#Preview {
    PaywallView().environment(EntitlementStore())
}
