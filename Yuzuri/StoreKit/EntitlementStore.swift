import Foundation
import StoreKit

/// 買い切り（非消費型）エンタイトルメントの単一ソース。
/// 過去アプリの教訓を実装に固定化:
///  - 商品は eager に取得（Paywall 側で `.task` から `load()` を呼ぶ）
///  - 起動時・購入後・復元後に `Transaction.currentEntitlements` を再評価
@Observable
@MainActor
final class EntitlementStore {
    static let productID = "com.chen.yuzuri.fullunlock"

    private(set) var product: Product?
    private(set) var isUnlocked = false
    private(set) var purchaseFailed = false

    /// 商品メタデータを取得（Paywall 表示前に呼ぶ）。
    func load() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            product = nil
        }
        await refresh()
    }

    /// 現在のエンタイトルメントを再評価。
    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let txn) = result, txn.productID == Self.productID {
                isUnlocked = true
                return
            }
        }
        isUnlocked = false
    }

    /// 購入。失敗時はボタンを無効化できるようフラグを立てる（審査 2.1(a) 対策）。
    func purchase() async {
        guard let product else { purchaseFailed = true; return }
        do {
            let result = try await product.purchase()
            if case .success(.verified(let txn)) = result {
                await txn.finish()
                await refresh()
            }
        } catch {
            purchaseFailed = true
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    #if DEBUG
    func debugToggleUnlock() { isUnlocked.toggle() }
    #endif
}
