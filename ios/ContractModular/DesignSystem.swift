
import SwiftUI

enum AppSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

struct AppCard<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.separator.opacity(0.35), lineWidth: 0.5)
            }
    }
}

struct StatusPill: View {
    let status: ContractStatus
    var body: some View {
        Label(status.rawValue, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: .capsule)
    }
    private var icon: String {
        switch status {
        case .draft: "pencil"
        case .review: "eye"
        case .ready: "checkmark.circle"
        case .signed: "checkmark.seal"
        case .archived: "archivebox"
        }
    }
    private var color: Color {
        switch status {
        case .draft: .secondary
        case .review: .orange
        case .ready: .blue
        case .signed: .green
        case .archived: .gray
        }
    }
}

struct ModuleIcon: View {
    let module: ModuleKind
    var body: some View {
        Image(systemName: module.symbol)
            .font(.title3.weight(.semibold))
            .frame(width: 42, height: 42)
            .foregroundStyle(.tint)
            .background(.quaternary, in: .rect(cornerRadius: 13))
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .glassEffect(.regular.tint(.accentColor).interactive(), in: .capsule)
        .accessibilityAddTraits(.isButton)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        AppCard {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .padding(.top, 4)
        }
    }
}

struct ModuleRow: View {
    let module: ModuleKind
    let completion: Int
    let enabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            ModuleIcon(module: module)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("\(module.rawValue) · \(module.title)")
                        .font(.headline)
                    if enabled {
                        Text("Activo")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(module.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(completion), total: 100)
                    .progressViewStyle(.linear)
                    .tint(completion == 100 ? .green : .accentColor)
            }
            Spacer()
            Text("\(completion)%")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        }
    }
}
