import SwiftUI
import SwiftData
import YuzuriKit

struct CategoryView: View {
    let category: CategoryDef
    @Environment(\.modelContext) private var ctx
    @Query private var allEntries: [NoteEntry]

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
                    FieldRowView(field: field, value: binding(for: field))
                }
            }

            // free text
            Section(header: Text("メモ")) {
                TextEditor(text: freeTextBinding)
                    .frame(minHeight: 80)
            }

            // done toggle
            Section {
                Toggle("記入完了", isOn: doneBinding)
            }
        }
        .navigationTitle(category.defaultLabel)
        .navigationBarTitleDisplayMode(.inline)
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
