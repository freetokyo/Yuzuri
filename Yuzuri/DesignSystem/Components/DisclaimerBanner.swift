import SwiftUI

/// 画面常置の免責バナー。
struct DisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")   // SF Symbol（絵文字は使わない）
            Text(Compliance.disclaimerShort)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DisclaimerBanner().padding()
}
