
import Foundation

enum ContractStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "Borrador"
    case review = "En revisión"
    case ready = "Listo para firma"
    case signed = "Firmado"
    case archived = "Archivado"
    var id: String { rawValue }
}

enum ModuleKind: String, Codable, CaseIterable, Identifiable {
    case loan = "A"
    case guarantee = "B"
    case training = "C"
    case nda = "D"
    case sla = "E"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .loan: "Préstamo"
        case .guarantee: "Aval"
        case .training: "Permanencia"
        case .nda: "Confidencialidad"
        case .sla: "Desempeño"
        }
    }

    var subtitle: String {
        switch self {
        case .loan: "Préstamo contractual"
        case .guarantee: "Garantía personal"
        case .training: "Especialización profesional"
        case .nda: "Acuerdo de confidencialidad"
        case .sla: "KPIs y calidad"
        }
    }

    var symbol: String {
        switch self {
        case .loan: "banknote"
        case .guarantee: "checkmark.shield"
        case .training: "graduationcap"
        case .nda: "lock.doc"
        case .sla: "chart.bar.xaxis"
        }
    }
}

enum PartyRole: String, Codable, CaseIterable, Identifiable {
    case company = "Empresa"
    case worker = "Trabajador"
    case guarantor = "Avalista"
    var id: String { rawValue }
}

struct Party: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var role: PartyRole
    var name: String = ""
    var document: String = ""
    var address: String = ""
    var email: String = ""
    var phone: String = ""
    var position: String = ""
    var category: String = ""
    var convention: String = ""
}

struct LoanDetails: Codable, Hashable {
    var amount: Decimal = 0
    var interestRate: Decimal = 0
    var termMonths: Int = 0
    var monthlyPayment: Decimal = 0
    var startDate: Date = .now
    var finalDate: Date = .now
    var purpose: String = ""
    var repaymentMethod: String = "Transferencia bancaria"
}

struct GuaranteeDetails: Codable, Hashable {
    var limit: Decimal = 0
    var endDate: Date = .now
    var solidarity: Bool = true
    var scope: String = "Exclusivamente obligaciones derivadas del préstamo del Módulo A."
}

struct TrainingDetails: Codable, Hashable {
    var description: String = ""
    var provider: String = ""
    var startDate: Date = .now
    var endDate: Date = .now
    var cost: Decimal = 0
    var certification: String = ""
    var project: String = ""
    var durationMonths: Int = 0
    var proportionalIndemnity: Bool = true
}

struct NDASettings: Codable, Hashable {
    var technical = true
    var commercial = true
    var financial = true
    var hr = true
    var postEmploymentYears: Int = 0
    var businessSecretWhileProtected = true
}

struct KPI: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var metric: String
    var target: String
    var unit: String
    var cadence: String
}

struct SLASettings: Codable, Hashable {
    var scope: String = ""
    var responsible: String = ""
    var trackingSystem: String = ""
    var reviewCadence: String = "Mensual"
    var kpis: [KPI] = []
}

struct ContractCase: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date = .now
    var updatedAt: Date = .now
    var status: ContractStatus = .draft
    var parties: [Party] = []
    var activeModules: Set<ModuleKind> = Set(ModuleKind.allCases)
    var loan = LoanDetails()
    var guarantee = GuaranteeDetails()
    var training = TrainingDetails()
    var nda = NDASettings()
    var sla = SLASettings()
    var placeOfSignature: String = ""
    var effectiveDate: Date = .now
    var noCompeteEnabled = false
    var noCompeteDuration = ""
    var noCompeteCompensation: Decimal = 0
    var noCompeteTerritory = ""
    var notes: String = ""

    var completedFields: Int {
        var total = 0
        var completed = 0
        func count(_ value: String) {
            total += 1
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completed += 1 }
        }
        parties.forEach {
            count($0.name); count($0.document)
            count($0.email)
        }
        if activeModules.contains(.loan) {
            total += 4
            if loan.amount > 0 { completed += 1 }
            if loan.termMonths > 0 { completed += 1 }
            if loan.monthlyPayment > 0 { completed += 1 }
            if !loan.purpose.isEmpty { completed += 1 }
        }
        if activeModules.contains(.guarantee) {
            total += 2
            if guarantee.limit > 0 { completed += 1 }
            if guarantee.endDate > .now.addingTimeInterval(-86_400) { completed += 1 }
        }
        if activeModules.contains(.training) {
            total += 4
            if !training.description.isEmpty { completed += 1 }
            if !training.provider.isEmpty { completed += 1 }
            if training.cost > 0 { completed += 1 }
            if training.durationMonths > 0 && training.durationMonths <= 24 { completed += 1 }
        }
        if activeModules.contains(.nda) { total += 1; completed += 1 }
        if activeModules.contains(.sla) {
            total += 2 + sla.kpis.count
            if !sla.scope.isEmpty { completed += 1 }
            if !sla.responsible.isEmpty { completed += 1 }
            completed += sla.kpis.filter { !$0.metric.isEmpty && !$0.target.isEmpty }.count
        }
        return total == 0 ? 0 : min(100, Int(Double(completed) / Double(total) * 100))
    }

    var validationIssues: [String] {
        var issues: [String] = []
        if parties.first(where: { $0.role == .company })?.name.isEmpty ?? true {
            issues.append("Falta identificar la Empresa.")
        }
        if parties.first(where: { $0.role == .worker })?.name.isEmpty ?? true {
            issues.append("Falta identificar al Trabajador.")
        }
        if activeModules.contains(.loan) {
            if loan.amount <= 0 { issues.append("El importe del préstamo no está definido.") }
            if loan.termMonths <= 0 { issues.append("El plazo del préstamo no está definido.") }
        }
        if activeModules.contains(.guarantee) && guarantee.limit <= 0 {
            issues.append("El límite del aval no está definido.")
        }
        if activeModules.contains(.training) {
            if training.durationMonths > 24 { issues.append("La duración indicada para permanencia supera 24 meses: revisar jurídicamente.") }
            if training.cost <= 0 { issues.append("El coste de formación no está documentado.") }
            if training.description.isEmpty { issues.append("Falta describir la especialización profesional.") }
        }
        if activeModules.contains(.sla) && sla.kpis.isEmpty {
            issues.append("El SLA no tiene métricas definidas.")
        }
        return issues
    }

    var moduleCompletion: [ModuleKind: Int] {
        Dictionary(uniqueKeysWithValues: ModuleKind.allCases.map { module in
            switch module {
            case .loan: (module, loan.amount > 0 && loan.termMonths > 0 && !loan.purpose.isEmpty ? 100 : 40)
            case .guarantee: (module, guarantee.limit > 0 ? 100 : 35)
            case .training: (module, !training.description.isEmpty && training.cost > 0 && training.durationMonths > 0 ? 100 : 45)
            case .nda: (module, 100)
            case .sla: (module, !sla.scope.isEmpty && !sla.kpis.isEmpty ? 100 : 50)
            }
        })
    }
}
