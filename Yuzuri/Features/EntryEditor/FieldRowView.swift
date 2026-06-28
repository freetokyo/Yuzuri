import SwiftUI
import YuzuriKit

struct FieldRowView: View {
    let field: FieldDef
    @Binding var value: String

    var body: some View {
        switch field.type {
        case "text":
            LabeledContent(field.defaultLabel) {
                TextField("", text: $value)
                    .multilineTextAlignment(.trailing)
            }

        case "multiline":
            VStack(alignment: .leading, spacing: 4) {
                Text(field.defaultLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $value)
                    .frame(minHeight: 60)
            }

        case "date":
            DateFieldRow(label: field.defaultLabel, value: $value)

        case "choice":
            LabeledContent(field.defaultLabel) {
                TextField("", text: $value)
                    .multilineTextAlignment(.trailing)
            }

        case "sensitive":
            LabeledContent(field.defaultLabel) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text(LocalizedStringKey("sensitive.encrypted"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        default:
            LabeledContent(field.defaultLabel) {
                TextField("", text: $value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

private struct DateFieldRow: View {
    let label: String
    @Binding var value: String

    private static let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f
    }()

    private var date: Binding<Date> {
        Binding(
            get: { Self.formatter.date(from: value) ?? .now },
            set: { value = Self.formatter.string(from: $0) }
        )
    }

    var body: some View {
        DatePicker(label, selection: date, displayedComponents: .date)
    }
}
