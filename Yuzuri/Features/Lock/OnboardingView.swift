import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)

                    Text("ユズリへようこそ")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "iphone",
                                   title: "完全オフライン",
                                   description: "入力した情報はこの端末内にのみ保存されます。外部に送信されることは一切ありません。")
                        FeatureRow(icon: "doc.text.fill",
                                   title: "PDF書き出し",
                                   description: "大切な情報をPDFとして書き出し、アプリがなくなっても紙や Files に残せます。")
                        FeatureRow(icon: "lock.fill",
                                   title: "秘匿モード",
                                   description: "口座番号などの機微な情報は端末内で暗号化して保存します。")
                        FeatureRow(icon: "person.fill.questionmark",
                                   title: "法的助言ではありません",
                                   description: "本アプリは情報の記録・整理ツールです。法律・税務・医療に関する専門的な助言は行いません。")
                    }
                    .padding(.horizontal)

                    Text("""
本アプリのデータは端末内のみに保存されます。
重要なご判断は専門家にご相談ください。
""")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    Button {
                        isPresented = false
                    } label: {
                        Text("確認して始める")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                    .accessibilityHint("オンボーディングを閉じてアプリを開始します")
                }
                .padding(.vertical, 40)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
