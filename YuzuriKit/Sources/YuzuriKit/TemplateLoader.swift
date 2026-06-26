import Foundation

// MARK: - Template loader with base+overlay merge

public enum TemplateLoader {

    public static func resolved(for locale: String, bundle: Bundle = .main) throws -> [CategoryDef] {
        let base = try decode(BaseTemplate.self, name: "template.base", bundle: bundle)
        let overlay: Overlay
        if let o = try? decode(Overlay.self, name: "template.\(locale)", bundle: bundle) {
            overlay = o
        } else {
            overlay = try decode(Overlay.self, name: "template.en", bundle: bundle)
        }
        return merge(base: base.categories, overlay: overlay)
    }

    // exposed for testing via @testable import
    static func merge(base: [CategoryDef], overlay: Overlay) -> [CategoryDef] {
        var cats = base

        if let rc = overlay.removeCategories {
            cats.removeAll { rc.contains($0.categoryKey) }
        }
        if let rf = overlay.removeFields {
            for i in cats.indices {
                cats[i].fields.removeAll { rf.contains($0.fieldKey) }
            }
        }
        if let ac = overlay.addCategories {
            cats.append(contentsOf: ac)
        }
        if let af = overlay.addFields {
            for op in af {
                guard let ci = cats.firstIndex(where: { $0.categoryKey == op.categoryKey }) else { continue }
                if let after = op.afterFieldKey,
                   let fi = cats[ci].fields.firstIndex(where: { $0.fieldKey == after }) {
                    cats[ci].fields.insert(op.field, at: fi + 1)
                } else {
                    cats[ci].fields.append(op.field)
                }
            }
        }
        if let ov = overlay.overrides {
            for i in cats.indices {
                if let o = ov[cats[i].categoryKey] {
                    if let v = o.order { cats[i].order = v }
                    if let v = o.disclaimerKey { cats[i].disclaimerKey = v }
                }
                for j in cats[i].fields.indices {
                    if let o = ov[cats[i].fields[j].fieldKey] {
                        if let v = o.defaultSensitive { cats[i].fields[j].defaultSensitive = v }
                    }
                }
            }
        }
        return cats.sorted { $0.order < $1.order }
    }

    private static func decode<T: Decodable>(_ type: T.Type, name: String, bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw TemplateError.fileNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

public enum TemplateError: Error {
    case fileNotFound(String)
}
