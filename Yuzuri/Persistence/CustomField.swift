import Foundation
import SwiftData

@Model
final class CustomField {
    var categoryKey: String
    var label: String
    var fieldType: String   // text/multiline/date/sensitive
    var isSensitive: Bool
    var sortOrder: Int
    var createdAt: Date

    init(categoryKey: String, label: String, fieldType: String = "text",
         isSensitive: Bool = false, sortOrder: Int = 0) {
        self.categoryKey = categoryKey
        self.label = label
        self.fieldType = fieldType
        self.isSensitive = isSensitive
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}
