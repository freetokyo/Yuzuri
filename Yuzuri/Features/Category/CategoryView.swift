import SwiftUI
import SwiftData
import YuzuriKit

struct CategoryView: View {
    let category: CategoryDef
    @Environment(\.modelContext) private var ctx
    @Query private var allEntries: [NoteEntry]
    @State private var sensitiveStore = SensitiveFieldStore()

    private var entry: NoteEntry? {
        allEntries.first { $0.categoryKey == category.categoryKey }
    }

    private func getOrCreate() -> NoteEntry {
        if let e = entry { return e }
        let e = NoteEntry(categoryKey: category.categoryKey)
        ctx.insert(e)
        return e
    }

    var body: some View {
        Form {
            // disclaimer
            if let key = category.disclaimerKey {
                Section {
                    Text(LocalizedStringKey(key))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // fields
            Section {
                ForEach(category.fields) { field in
                    if field.type == "sensitive" {
                        SensitiveFieldRowView(
                            field: field,
                            sensitiveStore: sensitiveStore,
                            categoryKey: category.categoryKey,
                            entry: entry,
                            ctx: ctx
                        )
                    } else {
                        FieldRowView(field: field, value: binding(for: field))
                    }
                }
            }

            // custom fields
            CustomItemView(category: category)

            // free text
            Section(header: Text(LocalizedStringKey("category.memo"))) {
                TextEditor(text: freeTextBinding)
                    .frame(minHeight: 80)
            }

            // done toggle
            Section {
                Toggle(LocalizedStringKey("category.done"), isOn: doneBinding)
            }
        }
        .navigationTitle(category.defaultLabel)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { sensitiveStore.lockSensitive() }
    }

    private func binding(for field: FieldDef) -> Binding<String> {
        Binding(
            get: { entry?.structuredValues[field.fieldKey] ?? "" },
            set: { newVal in
                let e = getOrCreate()
                if newVal.isEmpty {
                    e.structuredValues.removeValue(forKey: field.fieldKey)
                } else {
                    e.structuredValues[field.fieldKey] = newVal
                }
                e.updatedAt = .now
                try? ctx.save()
            }
        )
    }

    private var freeTextBinding: Binding<String> {
        Binding(
            get: { entry?.freeText ?? "" },
            set: { val in
                let e = getOrCreate()
                e.freeText = val
                e.updatedAt = .now
                try? ctx.save()
            }
        )
    }

    private var doneBinding: Binding<Bool> {
        Binding(
            get: { entry?.userMarkedDone ?? false },
            set: { val in
                let e = getOrCreate()
                e.userMarkedDone = val
                e.updatedAt = .now
                try? ctx.save()
            }
        )
    }
}

// MARK: - SensitiveFieldRowView

private struct SensitiveFieldRowView: View {
    let field: FieldDef
    let sensitiveStore: SensitiveFieldStore
    let categoryKey: String
    let entry: NoteEntry?
    let ctx: ModelContext

    @State private var inputText = ""
    @State private var isEditing = false

    var body: some View {
        if sensitiveStore.isUnlocked {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label(field.defaultLabel, systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(LocalizedStringKey("sensitive.lockButton")) { sensitiveStore.lockSensitive() }
                        .font(.caption)
                }
                if isEditing {
                    TextField(LocalizedStringKey("sensitive.enterValue"), text: $inputText)
                        .onSubmit { saveAndEnd() }
                } else {
                    Text(sensitiveStore.decrypted[field.fieldKey] ?? "")
                        .foregroundStyle(sensitiveStore.decrypted[field.fieldKey] == nil ? .secondary : .primary)
                        .onTapGesture {
                            inputText = sensitiveStore.decrypted[field.fieldKey] ?? ""
                            isEditing = true
                        }
                }
            }
        } else {
            Button {
                Task {
                    let ok = await sensitiveStore.unlockSensitive()
                    if ok, let e = entry { sensitiveStore.decryptAll(entry: e) }
                }
            } label: {
                Label(field.defaultLabel, systemImage: "lock.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Text(LocalizedStringKey("sensitive.tapToUnlock"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveAndEnd() {
        isEditing = false
        let e: NoteEntry
        if let existing = entry {
            e = existing
        } else {
            let ne = NoteEntry(categoryKey: categoryKey)
            ctx.insert(ne)
            e = ne
        }
        sensitiveStore.save(value: inputText, fieldKey: field.fieldKey, entry: e, ctx: ctx)
    }
}
