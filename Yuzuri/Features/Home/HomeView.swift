import SwiftUI
import SwiftData
import YuzuriKit

struct HomeView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(TemplateStore.self) private var templateStore
    @Query private var entries: [NoteEntry]

    private let calc = ProgressCalculator()

    private var entryMap: [String: EntrySnapshot] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.categoryKey, $0.snapshot()) })
    }

    private var overallRate: Double {
        calc.overallRate(categories: templateStore.categories, entries: entryMap)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DisclaimerBanner()

                    // 全体記入率リング
                    ProgressRingView(rate: overallRate)
                        .frame(width: 140, height: 140)
                        .padding(.top, 8)

                    // カテゴリ一覧
                    LazyVStack(spacing: 0) {
                        ForEach(templateStore.categories) { cat in
                            NavigationLink(value: cat) {
                                CategoryRowView(
                                    category: cat,
                                    status: calc.categoryStatus(category: cat, entry: entryMap[cat.categoryKey]),
                                    rate: calc.categoryRate(category: cat, entry: entryMap[cat.categoryKey])
                                )
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 16)
                        }
                    }
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("app.name"))
            .navigationDestination(for: CategoryDef.self) { cat in
                CategoryView(category: cat)
            }
        }
    }
}

// MARK: - ProgressRingView

private struct ProgressRingView: View {
    let rate: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: rate)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: rate)
            VStack(spacing: 2) {
                Text("\(Int(rate * 100))%")
                    .font(.title2.bold())
                Text(LocalizedStringKey("home.progress"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - CategoryRowView

private struct CategoryRowView: View {
    let category: CategoryDef
    let status: EntryStatus
    let rate: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(for: category.categoryKey))
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.defaultLabel)
                    .font(.body)
                if rate > 0 {
                    ProgressView(value: rate)
                        .tint(statusColor)
                }
            }

            Spacer()

            statusBadge
                .font(.caption2.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityIdentifier("cat_\(category.categoryKey)")
    }

    private var statusBadge: some View {
        Group {
            switch status {
            case .empty:
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            case .inProgress:
                Text("\(Int(rate * 100))%")
                    .foregroundStyle(.orange)
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .empty: .secondary
        case .inProgress: .orange
        case .done: .green
        }
    }

    private func categoryIcon(for key: String) -> String {
        switch key {
        case "profile": return "person.fill"
        case "family": return "person.2.fill"
        case "assets.bank": return "building.columns.fill"
        case "assets.securities": return "chart.line.uptrend.xyaxis"
        case "assets.realestate": return "house.fill"
        case "assets.other": return "creditcard.fill"
        case "liabilities": return "minus.circle.fill"
        case "insurance": return "shield.fill"
        case "pension": return "calendar.badge.clock"
        case "medical": return "cross.fill"
        case "care": return "heart.fill"
        case "funeral": return "leaf.fill"
        case "inheritance": return "doc.text.fill"
        case "will": return "pencil.and.list.clipboard"
        case "digital": return "laptopcomputer"
        case "contacts": return "phone.fill"
        case "farewell": return "envelope.fill"
        case "documents": return "folder.fill"
        case "pets": return "pawprint.fill"
        case "memo": return "note.text"
        default: return "square.grid.2x2.fill"
        }
    }
}

#Preview {
    HomeView()
        .environment(EntitlementStore())
        .environment(TemplateStore())
}
