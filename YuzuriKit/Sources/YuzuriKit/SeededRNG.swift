import Foundation

/// 決定論的な疑似乱数生成器（SplitMix64）。
///
/// なぜ標準 `SystemRandomNumberGenerator` を使わないか:
/// エンジンは「同じ入力 + 同じ seed → 同じ結果」を保証する必要があり、
/// それがテスト・再現・スクリーンショットの安定性の前提になる。
///
/// 落とし穴メモ（過去アプリの教訓）:
/// パスごとに `baseSeed &+ index` のような *加算派生* を seed に使うと、
/// 別 run の別パスと seed が衝突して「別 seed が同じ結果」になる。
/// 各ストリームは必ず *master RNG から派生* させること（`split()` を使う）。
public struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        // seed 0 でも縮退しないよう定数を混ぜる
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// 独立した子ストリームを払い出す（パス毎の seed 衝突を避ける正しい方法）。
    public mutating func split() -> SeededRNG {
        SeededRNG(seed: next())
    }
}
