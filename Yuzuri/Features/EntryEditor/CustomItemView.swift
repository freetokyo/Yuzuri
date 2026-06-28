import SwiftUI
import SwiftData
import YuzuriKit

struct CustomItemView: View {
    let category: CategoryDef
    @Environment(\.modelContext) private var ctx
    @Query private var allCustom: [CustomField]

    @State private var showAdd = false

    private var customFields: [CustomField] {
        allCustom.filter { $0.categoryKey == category.categoryKey }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Section(header: Text(LocalizedStringKey("customItem.section"))) {
            ForEach(customFields) { field in
                HStack {
                    Image(systemName: field.isSensitive ? "lock.fill" : "text.alignleft")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(field.label)
                    Spacer()
                    Text(field.fieldType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { indexSet in
                for i in indexSet { ctx.delete(customFields[i]) }
                try? ctx.save()
            }
            .onMove { from, to in
                var list = customFields
                list.move(fromOffsets: from, toOffset: to)
                for (i, f) in list.enumerated() { f.sortOrder = i }
                try? ctx.save()
            }

            Button {
                showAdd = true
            } label: {
                Label(LocalizedStringKey("customItem.add"), systemImage: "plus.circle")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddCustomFieldSheet(categoryKey: category.categoryKey) { label, type, sensitive in
                let order = customFields.count
                let field = CustomField(categoryKey: category.categoryKey,
                                        label: label, fieldType: type,
                                        isSensitive: sensitive, sortOrder: order)
                ctx.insert(field)
                try? ctx.save()
            }
        }
    }
}

struct AddCustomFieldSheet: View {
    let categoryKey: String
    let onAdd: (String, String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var type = "text"

    var body: some View {
        NavigationStack {
            Form {
                Section(LocalizedStringKey("customItem.labelSection")) {
                    TextField(LocalizedStringKey("customItem.labelField"), text: $label)
                }
                Section(LocalizedStringKey("customItem.typeSection")) {
                    Picker(LocalizedStringKey("customItem.typePicker"), selection: $type) {
                        Text(LocalizedStringKey("customItem.typeText")).tag("text")
                        Text(LocalizedStringKey("customItem.typeMultiline")).tag("multiline")
                        Text(LocalizedStringKey("customItem.typeDate")).tag("date")
                        Text(LocalizedStringKey("customItem.typeSensitive")).tag("sensitive")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(LocalizedStringKey("customItem.addTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("customItem.addButton")) {
                        let isSens = type == "sensitive"
                        onAdd(label, type, isSens)
                        dismiss()
                    }
                    .disabled(label.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("common.cancel")) { dismiss() }
                }
            }
        }
    }
}
