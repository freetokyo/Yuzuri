import SwiftUI
import SwiftData
import YuzuriKit

struct HomeView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(TemplateStore.self) private var templateStore
    @Query private var entries: [NoteEntry]

    @State private var celebratingCategory: String? = nil
    @State private var prevDoneSet: Set<String> = []

    private let calc = ProgressCalculator()

    private var entryMap: [String: EntrySnapshot] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.categoryKey, $0.snapshot()) })
    }

    private var overallRate: Double {
        calc.overallRate(categories: templateStore.categories, entries: entryMap)
    }

    private var startedCount: Int {
        templateStore.categories.filter {
            calc.categoryStatus(category: $0, entry: entryMap[$0.categoryKey]) != .empty
        }.count
    }

    private var filledFieldCount: Int {
        entries.reduce(0) { $0 + $1.structuredValues.values.filter { !$0.isEmpty }.count }
    }

    private var suggested: [CategoryDef] {
        CategoryGrouping.suggested(categories: templateStore.categories,
                                   entries: entryMap, calc: calc, limit: 3)
    }

    private var grouped: [(CategoryGroup, [CategoryDef])] {
        CategoryGrouping.grouped(categories: templateStore.categories)
    }

    private var currentDoneSet: Set<String> {
        Set(templateStore.categories
            .filter { calc.categoryStatus(category: $0, entry: entryMap[$0.categoryKey]) == .done }
            .map { $0.categoryKey })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DisclaimerBanner()

                    // ── 全体ダッシュボード ──────────────────────
                    DashboardView(
                        rate: overallRate,
                        startedCount: startedCount,
                        totalCount: templateStore.categories.count,
                        filledFields: filledFieldCount
                    )

                    // ── 次に書くとよい項目 ─────────────────────
                    if !suggested.isEmpty && overallRate < 1.0 {
                        SuggestedSection(
                            suggested: suggested,
                            entryMap: entryMap,
                            calc: calc
                        )
                    }

                    // ── グループ別カテゴリ一覧 ─────────────────
                    ForEach(grouped, id: \.0.id) { group, cats in
                        GroupSection(
                            group: group,
                            categories: cats,
                            entryMap: entryMap,
                            calc: calc
                        )
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("app.name"))
            .navigationDestination(for: CategoryDef.self) { cat in
                CategoryView(category: cat)
            }
        }
        // 完了祝いオーバーレイ
        .overlay {
            if let key = celebratingCategory,
               let cat = templateStore.categories.first(where: { $0.categoryKey == key }) {
                CelebrationOverlay(categoryLabel: cat.defaultLabel) {
                    withAnimation { celebratingCategory = nil }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onChange(of: entryMap) { _, _ in checkForNewlyCompleted() }
        .onAppear { prevDoneSet = currentDoneSet }
    }

    private func checkForNewlyCompleted() {
        let now = currentDoneSet
        let newlyDone = now.subtracting(prevDoneSet)
        if let first = newlyDone.first, celebratingCategory == nil {
            withAnimation(.spring(response: 0.4)) { celebratingCategory = first }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { celebratingCategory = nil }
            }
        }
        prevDoneSet = now
    }
}

// MARK: - DashboardView

private struct DashboardView: View {
    let rate: Double
    let startedCount: Int
    let totalCount: Int
    let filledFields: Int

    var body: some View {
        VStack(spacing: 16) {
            // 記入率リング
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: rate)
                VStack(spacing: 2) {
                    Text("\(Int(rate * 100))%")
                        .font(.title.bold())
                        .contentTransition(.numericText())
                    Text(LocalizedStringKey("home.progress"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            // 統計バッジ
            HStack(spacing: 20) {
                StatBadge(
                    value: "\(startedCount)/\(totalCount)",
                    labelKey: "stats.categoriesStarted"
                )
                StatBadge(
                    value: "\(filledFields)",
                    labelKey: "stats.fieldsCompleted"
                )
            }

            // モチベーションメッセージ
            if rate >= 1.0 {
                Label(LocalizedStringKey("stats.allDone"), systemImage: "star.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.orange)
            } else if rate > 0 {
                Text(LocalizedStringKey("stats.greatStart"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct StatBadge: View {
    let value: String
    let labelKey: String

    private var localizedLabel: String {
        // format string に %d が含まれる場合は数値不要（valueに含まれているため）
        let s = NSLocalizedString(labelKey, comment: "")
        return s.contains("%d") ? s.replacingOccurrences(of: "%d", with: "") : s
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .contentTransition(.numericText())
            Text(localizedLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 90)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - SuggestedSection

private struct SuggestedSection: View {
    let suggested: [CategoryDef]
    let entryMap: [String: EntrySnapshot]
    let calc: ProgressCalculator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("stats.suggestedNext"), systemImage: "arrow.right.circle.fill")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggested) { cat in
                        NavigationLink(value: cat) {
                            SuggestedCard(
                                category: cat,
                                rate: calc.categoryRate(category: cat,
                                                        entry: entryMap[cat.categoryKey])
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct SuggestedCard: View {
    let category: CategoryDef
    let rate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: categoryIcon(for: category.categoryKey))
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(category.defaultLabel)
                .font(.subheadline.bold())
                .lineLimit(2)
            if rate > 0 {
                ProgressView(value: rate)
                    .tint(.orange)
            } else {
                Text(LocalizedStringKey("status.empty"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 130, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - GroupSection

private struct GroupSection: View {
    let group: CategoryGroup
    let categories: [CategoryDef]
    let entryMap: [String: EntrySnapshot]
    let calc: ProgressCalculator

    @State private var isExpanded = true

    private var groupRate: Double {
        let rates = categories.map { calc.categoryRate(category: $0, entry: entryMap[$0.categoryKey]) }
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }

    private var doneCount: Int {
        categories.filter { calc.categoryStatus(category: $0, entry: entryMap[$0.categoryKey]) == .done }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // グループヘッダー
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: group.iconName)
                        .font(.callout)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(group.labelKey))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(doneCount)/\(categories.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // グループ進捗バー
                    ProgressView(value: groupRate)
                        .tint(groupRate >= 1 ? .green : .accentColor)
                        .frame(width: 60)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // カテゴリ一覧
            if isExpanded {
                LazyVStack(spacing: 0) {
                    ForEach(categories) { cat in
                        Divider().padding(.leading, 52)
                        NavigationLink(value: cat) {
                            CategoryRowView(
                                category: cat,
                                status: calc.categoryStatus(category: cat,
                                                            entry: entryMap[cat.categoryKey]),
                                rate: calc.categoryRate(category: cat,
                                                        entry: entryMap[cat.categoryKey])
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("cat_\(cat.categoryKey)")
                    }
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
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
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.defaultLabel)
                    .font(.subheadline)
                if rate > 0 && rate < 1 {
                    ProgressView(value: rate)
                        .tint(.orange)
                }
            }

            Spacer()

            statusView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .empty:
            Image(systemName: "circle").foregroundStyle(.tertiary)
        case .inProgress:
            Text("\(Int(rate * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
    }
}

// MARK: - CelebrationOverlay

private struct CelebrationOverlay: View {
    let categoryLabel: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: true)

            Text(LocalizedStringKey("complete.congrats"))
                .font(.title2.bold())
            Text(categoryLabel)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .onTapGesture { onDismiss() }
    }
}

// MARK: - Icon helper

private func categoryIcon(for key: String) -> String {
    switch key {
    case "profile":             return "person.fill"
    case "lifeStory":           return "book.fill"
    case "assets.bank":         return "building.columns.fill"
    case "assets.securities":   return "chart.line.uptrend.xyaxis"
    case "assets.insurance":    return "shield.fill"
    case "assets.realEstate":   return "house.fill"
    case "assets.cards":        return "creditcard.fill"
    case "assets.pension":      return "calendar.badge.clock"
    case "assets.liabilities":  return "minus.circle.fill"
    case "assets.other":        return "square.grid.2x2.fill"
    case "recurringPayments":   return "arrow.clockwise.circle.fill"
    case "digitalLegacy":       return "laptopcomputer"
    case "medical":             return "cross.fill"
    case "emergencyCard":       return "cross.case.fill"
    case "funeral":             return "leaf.fill"
    case "estatePlanning":      return "doc.text.fill"
    case "pets":                return "pawprint.fill"
    case "contacts":            return "phone.fill"
    case "messages":            return "envelope.fill"
    case "documentLocations":   return "folder.fill"
    default:                    return "square.fill"
    }
}

#Preview {
    HomeView()
        .environment(EntitlementStore())
        .environment(TemplateStore())
}
