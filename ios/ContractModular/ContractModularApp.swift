
import SwiftUI
import SwiftData

@main
struct ContractModularApp: App {
    @State private var app = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var app

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Inicio", systemImage: "rectangle.grid.2x2") }

            CasesView()
                .tabItem { Label("Expedientes", systemImage: "folder") }

            DocumentsView()
                .tabItem { Label("Documentos", systemImage: "doc.text") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(.accentColor)
        .tabViewStyle(.sidebarAdaptable)
    }
}

struct DashboardView: View {
    @Environment(AppStore.self) private var app
    @State private var showNewCase = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contract Modular")
                            .font(.largeTitle.bold())
                        Text("Crear, validar y preparar expedientes documentales por módulos.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    PrimaryActionButton(title: "Nuevo expediente", systemImage: "plus") {
                        showNewCase = true
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: AppSpacing.md)], spacing: AppSpacing.md) {
                        MetricCard(title: "Expedientes", value: "\(app.cases.count)", symbol: "folder")
                        MetricCard(title: "Listos", value: "\(app.cases.filter { $0.status == .ready || $0.status == .signed }.count)", symbol: "checkmark.circle")
                        MetricCard(title: "En revisión", value: "\(app.cases.filter { $0.status == .review }.count)", symbol: "eye")
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Actividad reciente")
                            .font(.title2.bold())

                        ForEach(app.cases.prefix(4)) { item in
                            NavigationLink {
                                CaseDetailView(caseID: item.id)
                            } label: {
                                AppCard {
                                    HStack(spacing: 14) {
                                        Image(systemName: "doc.badge.gearshape")
                                            .font(.title2)
                                            .foregroundStyle(.tint)
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(2)
                                            Text("Actualizado \(item.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        StatusPill(status: item.status)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .navigationTitle("Inicio")
            .sheet(isPresented: $showNewCase) {
                NewCaseFlowView()
            }
        }
    }
}

struct CasesView: View {
    @Environment(AppStore.self) private var app
    @State private var showNewCase = false

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { app.selectedCaseID },
                set: { app.selectedCaseID = $0 }
            )) {
                Section("Expedientes") {
                    ForEach(app.visibleCases) { item in
                        NavigationLink(value: item.id) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                    Text("\(item.completedFields)% completo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tag(item.id)
                    }
                    .onDelete { indexes in
                        indexes.map { app.visibleCases[$0] }.forEach(app.delete)
                    }
                }
            }
            .navigationTitle("Expedientes")
            .searchable(text: Binding(get: { app.searchText }, set: { app.searchText = $0 }))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewCase = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nuevo expediente")
                }
            }
        } detail: {
            if let id = app.selectedCaseID {
                CaseDetailView(caseID: id)
            } else {
                EmptyStateCard(
                    title: "Selecciona un expediente",
                    message: "Crea uno nuevo o selecciona uno de la lista.",
                    symbol: "folder"
                )
            }
        }
        .sheet(isPresented: $showNewCase) {
            NewCaseFlowView()
        }
    }
}

struct CaseDetailView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID

    private var item: ContractCase? { app.cases.first(where: { $0.id == caseID }) }

    var body: some View {
        Group {
            if let item {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            AppCard {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.title)
                                            .font(.title.bold())
                                        HStack {
                                            StatusPill(status: item.status)
                                            Text("\(item.completedFields)%")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                ProgressView(value: Double(item.completedFields), total: 100)
                                    .tint(.accentColor)
                                    .padding(.top, 10)
                            }

                            SectionCard(title: "Módulos", symbol: "square.grid.2x2") {
                                ForEach(ModuleKind.allCases) { module in
                                    ModuleRow(module: module, completion: item.moduleCompletion[module] ?? 0, enabled: item.activeModules.contains(module))
                                }
                            }

                            SectionCard(title: "Flujo", symbol: "arrow.triangle.branch") {
                                NavigationLink {
                                    PartiesView(caseID: caseID)
                                } label: {
                                    FlowRow(title: "Partes", subtitle: "\(item.parties.count) perfiles", symbol: "person.2")
                                }

                                NavigationLink {
                                    ModuleCatalogView(caseID: caseID)
                                } label: {
                                    FlowRow(title: "Configuración modular", subtitle: "Activar y editar A–E", symbol: "square.grid.2x2")
                                }

                                NavigationLink {
                                    ReviewView(caseID: caseID)
                                } label: {
                                    FlowRow(title: "Validación", subtitle: "\(item.validationIssues.count) incidencias", symbol: "checkmark.shield")
                                }

                                NavigationLink {
                                    CaseDocumentView(caseID: caseID)
                                } label: {
                                    FlowRow(title: "Documento", subtitle: "Vista previa y exportación", symbol: "doc.richtext")
                                }

                                NavigationLink {
                                    SignatureView(caseID: caseID)
                                } label: {
                                    FlowRow(title: "Firmas", subtitle: "Captura de referencias y estado", symbol: "signature")
                                }
                            }

                            SectionCard(title: "Metadatos", symbol: "info.circle") {
                                LabeledContent("Creado", value: item.createdAt.formatted(date: .long, time: .shortened))
                                LabeledContent("Actualizado", value: item.updatedAt.formatted(date: .long, time: .shortened))
                                LabeledContent("ID", value: item.id.uuidString.prefix(8).uppercased())
                            }
                        }
                        .padding(AppSpacing.lg)
                    }
                    .navigationTitle("Expediente")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            EditButton()
                        }
                    }
                }
            } else {
                EmptyStateCard(title: "Expediente no encontrado", message: "El identificador seleccionado ya no existe.", symbol: "exclamationmark.triangle")
            }
        }
    }
}

struct NewCaseFlowView: View {
    @Environment(AppStore.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var title = ""
    @State private var modules = Set(ModuleKind.allCases)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)

                TabView(selection: $step) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Identificar")
                            .font(.largeTitle.bold())
                        TextField("Nombre del expediente", text: $title)
                            .textFieldStyle(.roundedBorder)
                        Text("Usa un título corto y reconocible. El resto de la información se completa después.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                    .tag(0)

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Seleccionar módulos")
                            .font(.largeTitle.bold())
                        ForEach(ModuleKind.allCases) { module in
                            Button {
                                if modules.contains(module) {
                                    modules.remove(module)
                                } else {
                                    modules.insert(module)
                                }
                            } label: {
                                HStack {
                                    ModuleIcon(module: module)
                                    VStack(alignment: .leading) {
                                        Text("\(module.rawValue) · \(module.title)").font(.headline)
                                        Text(module.subtitle).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: modules.contains(module) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(modules.contains(module) ? .tint : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                    .tag(1)

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Revisar")
                            .font(.largeTitle.bold())
                        AppCard {
                            LabeledContent("Expediente", value: title.isEmpty ? "Nuevo expediente" : title)
                            LabeledContent("Módulos", value: modules.map(\.rawValue).sorted().joined(separator: ", "))
                            LabeledContent("Diseño", value: "Nativo SwiftUI + adaptación Apple")
                        }
                        Text("Se creará un borrador. Ningún módulo se considera jurídicamente validado por la aplicación.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Nuevo expediente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(step == 2 ? "Crear" : "Continuar") {
                        if step < 2 {
                            withAnimation(.snappy) { step += 1 }
                        } else {
                            _ = app.create(title: title, modules: modules)
                            dismiss()
                        }
                    }
                    .disabled(step == 0 && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct PartiesView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID
    @State private var draft: ContractCase

    init(caseID: UUID) {
        self.caseID = caseID
        _draft = State(initialValue: ContractCase(title: "Cargando…"))
    }

    var body: some View {
        Form {
            Section("Partes") {
                ForEach(PartyRole.allCases) { role in
                    PartyEditor(role: role, draft: $draft)
                }
            }
        }
        .navigationTitle("Partes")
        .onAppear {
            if let item = app.cases.first(where: { $0.id == caseID }) { draft = item }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") { app.replace(draft) }
            }
        }
    }
}

struct PartyEditor: View {
    let role: PartyRole
    @Binding var draft: ContractCase

    private var partyIndex: Int {
        if let index = draft.parties.firstIndex(where: { $0.role == role }) { return index }
        return -1
    }

    var body: some View {
        Group {
            if partyIndex >= 0 {
                Section {
                    TextField("Nombre y apellidos / Razón social", text: $draft.parties[partyIndex].name)
                    TextField("DNI / NIF / CIF", text: $draft.parties[partyIndex].document)
                    TextField("Domicilio", text: $draft.parties[partyIndex].address)
                    TextField("Email", text: $draft.parties[partyIndex].email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Teléfono", text: $draft.parties[partyIndex].phone)
                        .keyboardType(.phonePad)
                    if role == .worker {
                        TextField("Puesto", text: $draft.parties[partyIndex].position)
                        TextField("Categoría", text: $draft.parties[partyIndex].category)
                        TextField("Convenio colectivo", text: $draft.parties[partyIndex].convention)
                    }
                } header: {
                    Label(role.rawValue, systemImage: role == .company ? "building.2" : role == .worker ? "person.crop.circle" : "checkmark.shield")
                }
            } else {
                Text("Perfil \(role.rawValue) no disponible")
            }
        }
    }
}

struct ModuleCatalogView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID
    @State private var draft: ContractCase

    init(caseID: UUID) {
        self.caseID = caseID
        _draft = State(initialValue: ContractCase(title: "Cargando…"))
    }

    var body: some View {
        List {
            ForEach(ModuleKind.allCases) { module in
                Toggle(isOn: Binding(
                    get: { draft.activeModules.contains(module) },
                    set: { enabled in
                        if enabled { draft.activeModules.insert(module) }
                        else { draft.activeModules.remove(module) }
                    }
                )) {
                    HStack {
                        ModuleIcon(module: module)
                        VStack(alignment: .leading) {
                            Text("\(module.rawValue) · \(module.title)")
                            Text(module.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                NavigationLink("Editar módulo A · Préstamo") { LoanEditor(draft: $draft) }
                NavigationLink("Editar módulo B · Aval") { GuaranteeEditor(draft: $draft) }
                NavigationLink("Editar módulo C · Permanencia") { TrainingEditor(draft: $draft) }
                NavigationLink("Editar módulo D · NDA") { NDAEditor(draft: $draft) }
                NavigationLink("Editar módulo E · SLA") { SLAEditor(draft: $draft) }
            } header: {
                Text("Configuración")
            }
        }
        .navigationTitle("Módulos")
        .onAppear {
            if let item = app.cases.first(where: { $0.id == caseID }) { draft = item }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") { app.replace(draft) }
            }
        }
    }
}

struct LoanEditor: View {
    @Binding var draft: ContractCase
    var body: some View {
        Form {
            Section("Préstamo") {
                TextField("Importe", value: $draft.loan.amount, format: .number)
                    .keyboardType(.decimalPad)
                TextField("TIN anual (%)", value: $draft.loan.interestRate, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Plazo (meses)", value: $draft.loan.termMonths, format: .number)
                    .keyboardType(.numberPad)
                TextField("Cuota mensual", value: $draft.loan.monthlyPayment, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Destino", text: $draft.loan.purpose, axis: .vertical)
                Picker("Reintegro", selection: $draft.loan.repaymentMethod) {
                    Text("Transferencia bancaria").tag("Transferencia bancaria")
                    Text("Compensación").tag("Compensación")
                    Text("Otro").tag("Otro")
                }
            }
        }
        .navigationTitle("Módulo A · Préstamo")
    }
}

struct GuaranteeEditor: View {
    @Binding var draft: ContractCase
    var body: some View {
        Form {
            Section("Aval") {
                TextField("Límite de garantía", value: $draft.guarantee.limit, format: .number)
                    .keyboardType(.decimalPad)
                DatePicker("Fecha de fin", selection: $draft.guarantee.endDate, displayedComponents: .date)
                Toggle("Carácter solidario", isOn: $draft.guarantee.solidarity)
                TextField("Alcance", text: $draft.guarantee.scope, axis: .vertical)
            }
        }
        .navigationTitle("Módulo B · Aval")
    }
}

struct TrainingEditor: View {
    @Binding var draft: ContractCase
    var body: some View {
        Form {
            Section("Formación") {
                TextField("Descripción", text: $draft.training.description, axis: .vertical)
                TextField("Centro / proveedor", text: $draft.training.provider)
                DatePicker("Inicio", selection: $draft.training.startDate, displayedComponents: .date)
                DatePicker("Fin", selection: $draft.training.endDate, displayedComponents: .date)
                TextField("Coste", value: $draft.training.cost, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Certificación", text: $draft.training.certification)
                TextField("Proyecto específico", text: $draft.training.project, axis: .vertical)
                Stepper("Permanencia: \(draft.training.durationMonths) meses", value: $draft.training.durationMonths, in: 0...24)
                Toggle("Indemnización proporcional", isOn: $draft.training.proportionalIndemnity)
            }
        }
        .navigationTitle("Módulo C · Permanencia")
    }
}

struct NDAEditor: View {
    @Binding var draft: ContractCase
    var body: some View {
        Form {
            Section("Información protegida") {
                Toggle("Información técnica", isOn: $draft.nda.technical)
                Toggle("Información comercial", isOn: $draft.nda.commercial)
                Toggle("Información financiera", isOn: $draft.nda.financial)
                Toggle("Información de RRHH", isOn: $draft.nda.hr)
            }
            Section("Duración") {
                Stepper("Años tras la relación: \(draft.nda.postEmploymentYears)", value: $draft.nda.postEmploymentYears, in: 0...20)
                Toggle("Secretos empresariales mientras estén protegidos", isOn: $draft.nda.businessSecretWhileProtected)
            }
        }
        .navigationTitle("Módulo D · NDA")
    }
}

struct SLAEditor: View {
    @Binding var draft: ContractCase
    var body: some View {
        Form {
            Section("Ámbito") {
                TextField("Funciones / servicios", text: $draft.sla.scope, axis: .vertical)
                TextField("Responsable de medición", text: $draft.sla.responsible)
                TextField("Sistema de seguimiento", text: $draft.sla.trackingSystem)
                Picker("Revisión", selection: $draft.sla.reviewCadence) {
                    Text("Mensual").tag("Mensual")
                    Text("Trimestral").tag("Trimestral")
                    Text("Semestral").tag("Semestral")
                }
            }
            Section("KPIs") {
                ForEach($draft.sla.kpis) { $kpi in
                    VStack(alignment: .leading) {
                        TextField("Métrica", text: $kpi.metric)
                        TextField("Objetivo", text: $kpi.target)
                        TextField("Unidad", text: $kpi.unit)
                        TextField("Periodicidad", text: $kpi.cadence)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { draft.sla.kpis.remove(atOffsets: $0) }

                Button("Añadir KPI", systemImage: "plus") {
                    draft.sla.kpis.append(KPI(metric: "", target: "", unit: "", cadence: "Mensual"))
                }
            }
        }
        .navigationTitle("Módulo E · SLA")
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 26)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
    }
}
