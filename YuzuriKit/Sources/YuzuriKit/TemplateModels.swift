import Foundation

// MARK: - Decodable models for template JSON

public struct FieldDef: Codable, Identifiable, Hashable, Sendable {
    public let fieldKey: String
    public let labelKey: String
    public let defaultLabel: String
    public let type: String
    public var defaultSensitive: Bool

    public var id: String { fieldKey }

    public init(fieldKey: String, labelKey: String, defaultLabel: String,
                type: String, defaultSensitive: Bool) {
        self.fieldKey = fieldKey
        self.labelKey = labelKey
        self.defaultLabel = defaultLabel
        self.type = type
        self.defaultSensitive = defaultSensitive
    }
}

public struct CategoryDef: Codable, Identifiable, Hashable, Sendable {
    public let categoryKey: String
    public let labelKey: String
    public let defaultLabel: String
    public var order: Int
    public var disclaimerKey: String?
    public var fields: [FieldDef]

    public var id: String { categoryKey }

    public init(categoryKey: String, labelKey: String, defaultLabel: String,
                order: Int, disclaimerKey: String? = nil, fields: [FieldDef] = []) {
        self.categoryKey = categoryKey
        self.labelKey = labelKey
        self.defaultLabel = defaultLabel
        self.order = order
        self.disclaimerKey = disclaimerKey
        self.fields = fields
    }
}

struct BaseTemplate: Codable {
    let role: String
    let templateVersion: String?
    let categories: [CategoryDef]
}

struct AddFieldOp: Codable {
    let categoryKey: String
    let afterFieldKey: String?
    let field: FieldDef
}

struct OverrideOp: Codable {
    let order: Int?
    let disclaimerKey: String?
    let defaultSensitive: Bool?
}

struct Overlay: Codable {
    let locale: String
    let templateVersion: String?
    let removeCategories: [String]?
    let removeFields: [String]?
    let addCategories: [CategoryDef]?
    let addFields: [AddFieldOp]?
    let overrides: [String: OverrideOp]?
}
