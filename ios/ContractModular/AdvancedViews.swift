
import SwiftUI
import LocalAuthentication

struct ReviewView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID
    @State private var pdfDocument = ContractPDFDocument()
    @State private var showingExporter = false

    private var item: ContractCase? { app.cases.first(where: { $0.id == caseID }) }

    var body: some View {
        ScrollView {
            if let item {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Estado de revisión", systemImage: item.validationIssues.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.headline)
                            Text(item.validationIssues.isEmpty ? "No se detectan incidencias formales en esta versión." : "\(item.validationIssues.count) incidencias requieren revisión.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    SectionCard(title: "Comprobaciones", symbol: "checklist") {
                        ValidationRow(title: "Identidad de las partes", valid: item.parties.filter { !$0.name.isEmpty }.count >= 2)
                        ValidationRow(title: "Módulos configurados", valid: !item.activeModules.isEmpty)
                        ValidationRow(title: "Préstamo", valid: !item.activeModules.contains(.loan) || (item.loan.amount > 0 && item.loan.termMonths > 0))
                        ValidationRow(title: "Aval", valid: !item.activeModules.contains(.guarantee) || item.guarantee.limit > 0)
                        ValidationRow(title: "Permanencia", valid: !item.activeModules.contains(.training) || (item.training.cost > 0 && item.training.durationMonths > 0 && item.training.durationMonths <= 24))
                        ValidationRow(title: "NDA", valid: !item.activeModules.contains(.nda) || item.nda.technical || item.nda.commercial || item.nda.financial || item.nda.hr)
                        ValidationRow(title: "SLA", valid: !item.activeModules.contains(.sla) || !item.sla.kpis.isEmpty)
                    }

                    if !item.validationIssues.isEmpty {
                        SectionCard(title: "Incidencias", symbol: "exclamationmark.triangle") {
                            ForEach(item.validationIssues, id: \.self) { issue in
                                Label(issue, systemImage: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    SectionCard(title: "Salida", symbol: "arrow.up.doc") {
                        HStack(spacing: 12) {
                            Button("Preparar PDF", systemImage: "doc.badge.gearshape") {
                                pdfDocument = ContractPDFRenderer.make(for: item)
                                showingExporter = true
                            }
                            .buttonStyle(.borderedProminent)

                            NavigationLink {
                                SignatureView(caseID: caseID)
                            } label: {
                                Label("Firma", systemImage: "signature")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            } else {
                EmptyStateCard(title: "Sin expediente", message: "No se puede revisar el elemento seleccionado.", symbol: "doc")
            }
        }
        .navigationTitle("Validación")
        .fileExporter(
            isPresented: $showingExporter,
            document: pdfDocument,
            contentType: .pdf,
            defaultFilename: item?.title.replacingOccurrences(of: "/", with: "-") ?? "contract-modular"
        )
    }
}

struct ValidationRow: View {
    let title: String
    let valid: Bool
    var body: some View {
        HStack {
            Image(systemName: valid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(valid ? .green : .secondary)
            Text(title)
            Spacer()
            Text(valid ? "OK" : "Revisar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(valid ? .green : .orange)
        }
        .padding(.vertical, 3)
    }
}

struct CaseDocumentView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID
    @State private var pdfDocument = ContractPDFDocument()
    @State private var showingExporter = false

    private var item: ContractCase? { app.cases.first(where: { $0.id == caseID }) }

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        AppCard {
                            Text(item.title)
                                .font(.title2.bold())
                            HStack {
                                StatusPill(status: item.status)
                                Text("v1")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: Double(item.completedFields), total: 100)
                        }

                        SectionCard(title: "Resumen documental", symbol: "doc.richtext") {
                            LabeledContent("Empresa", value: item.parties.first(where: { $0.role == .company })?.name ?? "Pendiente")
                            LabeledContent("Trabajador", value: item.parties.first(where: { $0.role == .worker })?.name ?? "Pendiente")
                            LabeledContent("Módulos", value: "\(item.activeModules.count)")
                            LabeledContent("Incidencias", value: "\(item.validationIssues.count)")
                        }

                        SectionCard(title: "Verificación", symbol: "qrcode") {
                            HStack(alignment: .top, spacing: 18) {
                                if let image = VerificationService.qrImage(for: VerificationService.verificationURL(for: item)) {
                                    Image(uiImage: image)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .background(.white)
                                        .clipShape(.rect(cornerRadius: 16))
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ID de documento")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(item.id.uuidString.uppercased())
                                        .font(.caption.monospaced())
                                        .textSelection(.enabled)
                                    Text("SHA-256")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                    Text(VerificationService.digest(for: item))
                                        .font(.caption2.monospaced())
                                        .textSelection(.enabled)
                                        .lineLimit(3)
                                }
                            }
                        }

                        SectionCard(title: "Exportar", symbol: "square.and.arrow.up") {
                            PrimaryActionButton(title: "Generar PDF", systemImage: "doc.fill") {
                                pdfDocument = ContractPDFRenderer.make(for: item)
                                showingExporter = true
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
                .navigationTitle("Documento")
                .fileExporter(
                    isPresented: $showingExporter,
                    document: pdfDocument,
                    contentType: .pdf,
                    defaultFilename: item.title.replacingOccurrences(of: "/", with: "-")
                )
            } else {
                EmptyStateCard(title: "Documento no disponible", message: "El expediente seleccionado no existe.", symbol: "doc")
            }
        }
    }
}

struct SignatureView: View {
    @Environment(AppStore.self) private var app
    let caseID: UUID
    @State private var strokes: [[CGPoint]] = []
    @State private var signed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Captura de firma")
                    .font(.largeTitle.bold())
                Text("Esta vista captura una referencia manuscrita para el expediente. La firma electrónica con efectos jurídicos requiere un sistema de firma que cumpla los requisitos aplicables.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SignaturePad(strokes: $strokes)
                    .frame(height: 260)
                    .background(.background.secondary, in: .rect(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    }

                HStack {
                    Button("Limpiar", systemImage: "eraser") {
                        strokes.removeAll()
                        signed = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Marcar como preparado", systemImage: "signature") {
                        signed = !strokes.isEmpty
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(strokes.isEmpty)
                }

                AppCard {
                    LabeledContent("Estado", value: signed ? "Preparado" : "Pendiente")
                    LabeledContent("Puntos capturados", value: strokes.reduce(0) { $0 + $1.count }.formatted())
                    if let item = app.cases.first(where: { $0.id == caseID }) {
                        LabeledContent("Expediente", value: item.title)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Firmas")
    }
}

struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]

    var body: some View {
        Canvas { context, _ in
            for points in strokes where points.count > 1 {
                var path = Path()
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if strokes.isEmpty || strokes[strokes.count - 1].last.map({ $0.distance(to: value.location) > 8 }) ?? true {
                        strokes.append([value.location])
                    } else {
                        strokes[strokes.count - 1].append(value.location)
                    }
                }
        )
        .accessibilityLabel("Área para dibujar la referencia de firma")
    }
}

struct DocumentsView: View {
    @Environment(AppStore.self) private var app

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.cases) { item in
                    NavigationLink {
                        CaseDocumentView(caseID: item.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.richtext")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text("\(item.completedFields)% · \(item.status.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .overlay {
                if app.cases.isEmpty {
                    EmptyStateCard(title: "Sin documentos", message: "Crea un expediente para generar su documento.", symbol: "doc")
                }
            }
            .navigationTitle("Documentos")
        }
    }
}

struct SettingsView: View {
    @AppStorage("biometricLock") private var biometricLock = false
    @State private var authMessage = "No probado"

    var body: some View {
        NavigationStack {
            Form {
                Section("Seguridad") {
                    Toggle("Bloqueo biométrico", isOn: $biometricLock)
                    Button("Probar autenticación", systemImage: "faceid") {
                        Task {
                            let context = LAContext()
                            var error: NSError?
                            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                                authMessage = error?.localizedDescription ?? "Biometría no disponible"
                                return
                            }
                            do {
                                let ok = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Proteger los expedientes contractuales")
                                authMessage = ok ? "Autenticación correcta" : "No autenticado"
                            } catch {
                                authMessage = error.localizedDescription
                            }
                        }
                    }
                    Text(authMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Interfaz") {
                    LabeledContent("Sistema", value: "SwiftUI")
                    LabeledContent("Material", value: "Liquid Glass / system materials")
                    LabeledContent("Adaptación", value: "iPhone · iPad")
                }

                Section("Documento") {
                    Text("La app es un sistema de preparación y revisión documental. La validez jurídica de cada cláusula depende del contexto y de la legislación aplicable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacidad") {
                    Text("Los datos de la demo permanecen en memoria. La persistencia real y la sincronización segura deberían incorporarse antes de producción.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
