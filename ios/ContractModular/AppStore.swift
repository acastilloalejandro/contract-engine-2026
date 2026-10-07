
import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    var cases: [ContractCase] = []
    var selectedCaseID: UUID?
    var searchText = ""

    init() {
        let sample = ContractCase(
            title: "Expediente demo · Contrato modular",
            parties: [
                Party(role: .company, name: "Empresa de demostración", document: "B00000000", email: "empresa@example.com"),
                Party(role: .worker, name: "Persona de demostración", document: "00000000X", position: "Especialista"),
                Party(role: .guarantor, name: "Avalista de demostración", document: "00000000Y")
            ],
            loan: LoanDetails(amount: 10_000, interestRate: 4.5, termMonths: 24, monthlyPayment: 434.16, purpose: "Formación y equipamiento"),
            guarantee: GuaranteeDetails(limit: 10_000),
            training: TrainingDetails(description: "Especialización profesional para proyecto específico", provider: "Proveedor formativo", cost: 3_200, durationMonths: 18),
            sla: SLASettings(scope: "Funciones y servicios definidos en el expediente", responsible: "Responsable designado", trackingSystem: "Sistema interno", kpis: [
                KPI(metric: "Asistencia", target: "95", unit: "%", cadence: "Mensual"),
                KPI(metric: "Tiempo de respuesta", target: "< 4", unit: "horas", cadence: "Por incidencia")
            ])
        )
        cases = [sample]
        selectedCaseID = sample.id
    }

    var visibleCases: [ContractCase] {
        guard !searchText.isEmpty else { return cases }
        return cases.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.parties.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var selectedCase: ContractCase? {
        guard let selectedCaseID else { return nil }
        return cases.first(where: { $0.id == selectedCaseID })
    }

    func replace(_ item: ContractCase) {
        guard let index = cases.firstIndex(where: { $0.id == item.id }) else { return }
        var copy = item
        copy.updatedAt = .now
        cases[index] = copy
    }

    @discardableResult
    func create(title: String, modules: Set<ModuleKind>) -> ContractCase {
        var item = ContractCase(title: title.isEmpty ? "Nuevo expediente" : title)
        item.activeModules = modules
        cases.insert(item, at: 0)
        selectedCaseID = item.id
        return item
    }

    func delete(_ item: ContractCase) {
        cases.removeAll(where: { $0.id == item.id })
        if selectedCaseID == item.id { selectedCaseID = cases.first?.id }
    }
}
