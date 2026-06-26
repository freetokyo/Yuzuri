import SwiftUI
import SwiftData
import YuzuriKit

struct CustomItemView: View {
    let category: CategoryDef
    @Environment(\.modelContext) private var ctx
    @Query private var allCustom: [CustomField]

    @State private var newLabel = ""
    @State private var newType = "text"
    @State private var newSensitive = false
    @State private var showAdd = false

    private var customFields: [CustomField] {
        allCustom.filter { $0.categoryKey == category.categoryKey }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Section(header: Text("カスタム項目")) {
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
                Label("カスタム項目を追加", systemImage: "plus.circle")
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
    @State private var sensitive = false

    var body: some View {
        NavigationStack {
            Form {
                Section("項目名") {
                    TextField("ラベル", text: $label)
                }
                Section("種別") {
                    Picker("種別", selection: $type) {
                        Text("テキスト").tag("text")
                        Text("複数行").tag("multiline")
                        Text("日付").tag("date")
                        Text("秘匿").tag("sensitive")
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle("秘匿項目として保存", isOn: $sensitive)
                }
            }
            .navigationTitle("カスタム項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        onAdd(label, sensitive ? "sensitive" : type, sensitive)
                        dismiss()
                    }
                    .disabled(label.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
