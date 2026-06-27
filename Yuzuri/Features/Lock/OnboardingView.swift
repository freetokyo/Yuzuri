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

                    Text(LocalizedStringKey("app.name"))
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "iphone",
                                   title: LocalizedStringKey("onboarding.offline"),
                                   description: LocalizedStringKey("onboarding.offlineBody"))
                        FeatureRow(icon: "doc.text.fill",
                                   title: LocalizedStringKey("onboarding.pdf"),
                                   description: LocalizedStringKey("onboarding.pdfBody"))
                        FeatureRow(icon: "lock.fill",
                                   title: LocalizedStringKey("onboarding.secure"),
                                   description: LocalizedStringKey("onboarding.secureBody"))
                        FeatureRow(icon: "person.fill.questionmark",
                                   title: LocalizedStringKey("onboarding.notAdvice"),
                                   description: LocalizedStringKey("onboarding.notAdviceBody"))
                    }
                    .padding(.horizontal)

                    Text(LocalizedStringKey("onboarding.footer"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        isPresented = false
                    } label: {
                        Text(LocalizedStringKey("onboarding.start"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                    .accessibilityHint("Closes onboarding and starts the app")
                }
                .padding(.vertical, 40)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

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
