
import Foundation
import CryptoKit
import PDFKit
import UIKit
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

struct ContractPDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum ContractPDFRenderer {
    static func make(for item: ContractCase) -> ContractPDFDocument {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 46

            func draw(_ text: String, font: UIFont, color: UIColor = .label, spacing: CGFloat = 8) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let rect = CGRect(x: 42, y: y, width: 511, height: 80)
                NSString(string: text).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                y += max(30, rect.height * 0.42) + spacing
                if y > 790 {
                    context.beginPage()
                    y = 46
                }
            }

            draw("CONTRACT MODULAR", font: .systemFont(ofSize: 21, weight: .bold))
            draw(item.title, font: .systemFont(ofSize: 15, weight: .semibold))
            draw("Estado: \(item.status.rawValue)", font: .systemFont(ofSize: 11), color: .secondaryLabel)
            draw("Progreso: \(item.completedFields)%", font: .systemFont(ofSize: 11), color: .secondaryLabel)

            draw("PARTES", font: .systemFont(ofSize: 13, weight: .bold), spacing: 5)
            for party in item.parties {
                draw("\(party.role.rawValue): \(party.name.isEmpty ? "Pendiente" : party.name)", font: .systemFont(ofSize: 11))
                if !party.document.isEmpty { draw("Documento: \(party.document)", font: .systemFont(ofSize: 10), color: .secondaryLabel) }
            }

            draw("MÓDULOS ACTIVOS", font: .systemFont(ofSize: 13, weight: .bold), spacing: 5)
            for module in ModuleKind.allCases where item.activeModules.contains(module) {
                draw("\(module.rawValue) · \(module.title) · \(item.moduleCompletion[module] ?? 0)%", font: .systemFont(ofSize: 11))
            }

            if !item.validationIssues.isEmpty {
                draw("REVISIÓN", font: .systemFont(ofSize: 13, weight: .bold), spacing: 5)
                item.validationIssues.forEach {
                    draw("• \($0)", font: .systemFont(ofSize: 10), color: .systemOrange)
                }
            }

            draw("NOTA", font: .systemFont(ofSize: 13, weight: .bold), spacing: 5)
            draw("Documento generado por una aplicación de preparación documental. No constituye asesoramiento jurídico ni certifica por sí mismo la validez jurídica de las cláusulas.", font: .systemFont(ofSize: 10), color: .secondaryLabel)

            let footer = "ID \(item.id.uuidString.prefix(8).uppercased()) · \(Date.now.formatted(date: .numeric, time: .shortened))"
            draw(footer, font: .monospacedSystemFont(ofSize: 8, weight: .regular), color: .tertiaryLabel, spacing: 0)
        }
        return ContractPDFDocument(data: data)
    }
}

enum VerificationService {
    static func digest(for item: ContractCase) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(item)) ?? Data()
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verificationURL(for item: ContractCase) -> String {
        let digest = digest(for: item)
        return "https://example.invalid/verify/\(item.id.uuidString)?sha256=\(digest)"
    }

    static func qrImage(for payload: String, size: CGFloat = 230) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.size.width
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
