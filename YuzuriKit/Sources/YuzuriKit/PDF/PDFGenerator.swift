import Foundation
#if canImport(UIKit)
import UIKit

// MARK: - PDFGenerator

public struct PDFOptions: Sendable {
    public var includeSensitive: Bool
    public var includeEmpty: Bool
    public var ownerName: String
    public var locale: String
    public var lastUpdated: Date

    public init(includeSensitive: Bool = false,
                includeEmpty: Bool = false,
                ownerName: String = "",
                locale: String = "ja",
                lastUpdated: Date = .now) {
        self.includeSensitive = includeSensitive
        self.includeEmpty = includeEmpty
        self.ownerName = ownerName
        self.locale = locale
        self.lastUpdated = lastUpdated
    }
}

public struct PDFCategory: Sendable {
    public let def: CategoryDef
    public let structuredValues: [String: String]
    public let freeText: String
    public let sensitiveValues: [String: String]   // 復号済み（全部入り版のみ）

    public init(def: CategoryDef, structuredValues: [String: String],
                freeText: String, sensitiveValues: [String: String] = [:]) {
        self.def = def
        self.structuredValues = structuredValues
        self.freeText = freeText
        self.sensitiveValues = sensitiveValues
    }
}

public enum PDFGenerator {

    // A4: 595 x 842 pt、Letter: 612 x 792 pt（1pt = 1/72 inch）
    static let a4 = CGRect(x: 0, y: 0, width: 595, height: 842)
    static let letter = CGRect(x: 0, y: 0, width: 612, height: 792)
    static let pdfMargin: CGFloat = 50

    public static func generate(
        categories: [PDFCategory],
        options: PDFOptions
    ) -> Data {
        let pageRect = options.locale == "en-US" ? letter : a4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            var state = DrawState(
                ctx: ctx,
                pageRect: pageRect,
                margin: pdfMargin,
                options: options
            )

            // 1. 表紙
            state.newPage()
            state.drawCover()

            // 2. はじめに（免責）
            state.newPage()
            state.drawDisclaimer()

            // 3. 目次（ページ数は後確定のため省略表示）
            state.newPage()
            state.drawTOC(categories: categories)

            // 4. 本文
            for cat in categories {
                state.drawCategory(cat)
            }

            // 5. 緊急医療カード
            state.newPage()
            state.drawEmergencyCard(categories: categories)

            // 6. 書類のありか
            state.newPage()
            state.drawDocumentLocations(categories: categories)
        }
    }
}

// MARK: - DrawState

private struct DrawState {
    let ctx: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    let options: PDFOptions

    let bodyFontSize: CGFloat = 11
    let headingFontSize: CGFloat = 16

    var currentY: CGFloat = 0
    var pageNumber: Int = 0
    var totalPages: Int = 0

    var contentWidth: CGFloat { pageRect.width - margin * 2 }
    var contentBottom: CGFloat { pageRect.height - margin - 24 }   // 24 for footer
    var contentTop: CGFloat { margin + (pageNumber > 1 ? 28 : 0) } // 28 for header

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    // MARK: Pages

    mutating func newPage() {
        ctx.beginPage()
        pageNumber += 1
        currentY = contentTop
        if pageNumber > 1 { drawHeader() }
        drawFooter()
    }

    // MARK: Primitives

    mutating func drawText(_ text: String, font: UIFont, color: UIColor = .label,
                           x: CGFloat? = nil, maxWidth: CGFloat? = nil, alignment: NSTextAlignment = .left) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = alignment
                p.lineHeightMultiple = 1.4
                return p
            }()
        ]
        let xPos = x ?? margin
        let width = maxWidth ?? contentWidth
        let str = NSAttributedString(string: text, attributes: attrs)
        let bounding = str.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                         options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        if currentY + bounding.height > contentBottom {
            newPage()
        }
        str.draw(in: CGRect(x: xPos, y: currentY, width: width, height: bounding.height))
        currentY += bounding.height + 4
        return bounding.height
    }

    mutating func drawHRule(color: UIColor = .separator) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: currentY))
        color.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        currentY += 6
    }

    // MARK: Header / Footer

    private func drawHeader() {
        let text = "\(options.ownerName)　\(dateString(options.lastUpdated))"
        let attr = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.secondaryLabel,
        ])
        attr.draw(at: CGPoint(x: margin, y: margin - 18))
        // header line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: margin - 6))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: margin - 6))
        UIColor.separator.setStroke()
        path.lineWidth = 0.3
        path.stroke()
    }

    private func drawFooter() {
        let text = "— \(pageNumber) —"
        let attr = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.secondaryLabel,
        ])
        let size = attr.size()
        attr.draw(at: CGPoint(x: (pageRect.width - size.width) / 2,
                               y: pageRect.height - margin + 8))
        // disclaimer footer on every page except cover
        if pageNumber > 1 {
            let disc = NSAttributedString(string: "機微情報を含む場合があります。保管・共有にご注意ください。", attributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: UIColor.tertiaryLabel,
            ])
            disc.draw(at: CGPoint(x: margin, y: pageRect.height - margin + 8))
        }
    }

    // MARK: - Cover

    mutating func drawCover() {
        currentY = pageRect.height * 0.25

        let titleText = options.locale.hasPrefix("en") ? "Ending Note" : "エンディングノート"
        drawText(titleText, font: .systemFont(ofSize: 28, weight: .bold),
                 alignment: .center)
        currentY += 8

        let appName = NSAttributedString(string: "ユズリ", attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel,
        ])
        appName.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: 20))
        currentY += 28

        if !options.ownerName.isEmpty {
            drawText(options.ownerName, font: .systemFont(ofSize: 18, weight: .medium), alignment: .center)
            currentY += 8
        }

        let dateStr = dateString(.now)
        drawText("作成日：\(dateStr)", font: .systemFont(ofSize: 11), color: .secondaryLabel, alignment: .center)
        drawText("最終更新：\(dateString(options.lastUpdated))", font: .systemFont(ofSize: 11),
                 color: .secondaryLabel, alignment: .center)

        currentY += 40

        let note = "※ この書類は遺言書ではなく、法的な効力はありません。"
        drawText(note, font: .italicSystemFont(ofSize: 10), color: .secondaryLabel, alignment: .center)
    }

    // MARK: - Disclaimer

    mutating func drawDisclaimer() {
        drawText("はじめに / ご確認ください", font: .systemFont(ofSize: headingFontSize, weight: .bold))
        currentY += 8

        let text = """
ユズリは、あなたの大切な情報を整理して残すための記録ツールです。入力した情報はこの端末内にのみ保存され、外部に送信されることはありません。

本アプリは法律・税務・医療に関する専門的な助言を行うものではありません。重要なご判断は、それぞれの専門家にご相談ください。

この書類には、口座やID等の機微な情報が含まれる場合があります。保管場所と共有する相手に十分ご注意ください。なお、この書類は遺言書ではなく、法的な効力はありません。
"""
        drawText(text, font: .systemFont(ofSize: bodyFontSize))
    }

    // MARK: - TOC

    mutating func drawTOC(categories: [PDFCategory]) {
        drawText("目次", font: .systemFont(ofSize: headingFontSize, weight: .bold))
        currentY += 8
        drawHRule()

        for cat in categories {
            drawText("• \(cat.def.defaultLabel)", font: .systemFont(ofSize: bodyFontSize))
        }
        currentY += 4
        drawText("緊急医療カード", font: .systemFont(ofSize: bodyFontSize))
        drawText("書類のありか一覧", font: .systemFont(ofSize: bodyFontSize))
    }

    // MARK: - Category Body

    mutating func drawCategory(_ cat: PDFCategory) {
        // カテゴリ見出しのためページ区切りを判定（残り高さ < 100 なら改ページ）
        if currentY > contentBottom - 100 { newPage() } else { currentY += 16 }

        drawText(cat.def.defaultLabel,
                 font: .systemFont(ofSize: headingFontSize, weight: .semibold))
        drawHRule()

        var hasContent = false

        for field in cat.def.fields {
            if field.type == "sensitive" {
                if options.includeSensitive {
                    let val = cat.sensitiveValues[field.fieldKey] ?? ""
                    if val.isEmpty && !options.includeEmpty { continue }
                    drawFieldRow(label: field.defaultLabel, value: val.isEmpty ? "（未入力）" : val)
                    hasContent = true
                } else {
                    drawFieldRow(label: field.defaultLabel, value: "（秘匿・非表示）",
                                 valueColor: .secondaryLabel)
                    hasContent = true
                }
            } else {
                let val = cat.structuredValues[field.fieldKey] ?? ""
                if val.isEmpty && !options.includeEmpty { continue }
                drawFieldRow(label: field.defaultLabel, value: val.isEmpty ? "（未入力）" : val)
                hasContent = true
            }
        }

        if !cat.freeText.isEmpty {
            drawFieldRow(label: "メモ", value: cat.freeText)
            hasContent = true
        }

        if !hasContent {
            drawText("（記入なし）", font: .systemFont(ofSize: bodyFontSize),
                     color: .tertiaryLabel)
        }

        // category disclaimer
        if let key = cat.def.disclaimerKey {
            currentY += 4
            drawText("※ \(disclaimerText(for: key))",
                     font: .italicSystemFont(ofSize: 9), color: .secondaryLabel)
        }
    }

    mutating func drawFieldRow(label: String, value: String, valueColor: UIColor = .label) {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: bodyFontSize),
            .foregroundColor: valueColor,
        ]

        let labelStr = NSAttributedString(string: label, attributes: labelAttr)
        let valueStr = NSAttributedString(string: value, attributes: valueAttr)
        let valueBound = valueStr.boundingRect(with: CGSize(width: contentWidth, height: 400),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

        let totalH = 14 + valueBound.height + 4
        if currentY + totalH > contentBottom { newPage() }

        labelStr.draw(at: CGPoint(x: margin, y: currentY))
        currentY += 14
        valueStr.draw(in: CGRect(x: margin + 8, y: currentY, width: contentWidth - 8, height: valueBound.height))
        currentY += valueBound.height + 8

        // light separator
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin + 8, y: currentY - 4))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: currentY - 4))
        UIColor.systemGray5.setStroke()
        path.lineWidth = 0.3
        path.stroke()
    }

    // MARK: - Emergency Card

    mutating func drawEmergencyCard(categories: [PDFCategory]) {
        drawText("緊急医療カード", font: .systemFont(ofSize: headingFontSize, weight: .bold))
        drawHRule()

        let text = "以下の情報を切り取り、財布等に携帯することをおすすめします。"
        drawText(text, font: .systemFont(ofSize: 9), color: .secondaryLabel)
        currentY += 8

        // dashed border
        let cardRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 160)
        let dash = UIBezierPath(rect: cardRect)
        UIColor.separator.setStroke()
        dash.setLineDash([4, 3], count: 2, phase: 0)
        dash.lineWidth = 0.8
        dash.stroke()

        currentY += 8

        // look up medical category
        let medCat = categories.first { $0.def.categoryKey == "medical" }
        let profileCat = categories.first { $0.def.categoryKey == "profile" }

        let name = profileCat?.structuredValues["profile.fullName"] ?? options.ownerName
        let bloodType = medCat?.structuredValues["medical.bloodType"] ?? "不明"
        let allergies = medCat?.structuredValues["medical.allergies"] ?? "（なし）"
        let medications = medCat?.structuredValues["medical.medications"] ?? "（なし）"
        let doctor = medCat?.structuredValues["medical.primaryDoctor"] ?? "（未記入）"

        for (label, value) in [
            ("氏名", name), ("血液型", bloodType),
            ("アレルギー", allergies), ("常用薬", medications),
            ("かかりつけ医", doctor),
        ] {
            let text = "\(label)：\(value)"
            let attr = NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label,
            ])
            attr.draw(at: CGPoint(x: margin + 10, y: currentY))
            currentY += 16
        }

        currentY = cardRect.maxY + 12
        drawText("※ 緊急医療カードの内容は記録ツールであり、医療上の指示ではありません。",
                 font: .italicSystemFont(ofSize: 8), color: .secondaryLabel)
    }

    // MARK: - Document Locations

    mutating func drawDocumentLocations(categories: [PDFCategory]) {
        drawText("書類のありか一覧", font: .systemFont(ofSize: headingFontSize, weight: .bold))
        drawHRule()

        let docCat = categories.first { $0.def.categoryKey == "documents" }

        if let cat = docCat {
            for field in cat.def.fields {
                let val = cat.structuredValues[field.fieldKey] ?? ""
                if val.isEmpty && !options.includeEmpty { continue }
                drawFieldRow(label: field.defaultLabel, value: val.isEmpty ? "（未記入）" : val)
            }
        } else {
            drawText("（書類のありか情報が記入されていません）",
                     font: .systemFont(ofSize: bodyFontSize), color: .tertiaryLabel)
        }
    }

    // MARK: - Helpers

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        f.locale = Locale(identifier: options.locale)
        return f.string(from: date)
    }

    private func disclaimerText(for key: String) -> String {
        switch key {
        case "disclaimer.will":
            return "エンディングノートは遺言書とは異なり、法的な効力はありません。法的に有効な遺言の作成については専門家にご相談ください。"
        case "disclaimer.tax":
            return "税金や相続税に関する具体的なご判断は、税理士などの専門家にご相談ください。"
        case "disclaimer.medical":
            return "ここに記録する内容は希望の記録であり、医療上の助言ではありません。"
        default:
            return key
        }
    }
}

#endif
