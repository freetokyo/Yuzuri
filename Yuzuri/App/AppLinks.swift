import Foundation

/// 法務・サポート系リンクの集約。Paywall と 設定の双方から参照する。
/// （Paywall に利用規約 / プライバシーのリンクが無いと審査 3.1.2 で却下されやすい。）
enum AppLinks {
    static let support = URL(string: "https://freetokyo.github.io/web/yuzuri/support.html")!
    static let terms = URL(string: "https://freetokyo.github.io/web/yuzuri/terms.html")!
    static let privacy = URL(string: "https://freetokyo.github.io/web/yuzuri/privacy.html")!
    static let marketing = URL(string: "https://freetokyo.github.io/web/yuzuri/index.html")!
}
