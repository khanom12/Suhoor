import SwiftUI

struct PermissionCardView: View {
    let presentation: PermissionPresentation
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingComfortable) {
            HStack(alignment: .firstTextBaseline) {
                Text(presentation.title)
                    .font(AppTypography.cardTitle)
                Spacer()
                Text(presentation.statusText)
                    .font(AppTypography.badge)
                    .foregroundStyle(statusColor)
            }

            Text(presentation.message)
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if presentation.showsProgress {
                ProgressView()
            }

            if presentation.showsSimulatorHint {
                Text(Strings.LocationAccess.simulatorHint)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = presentation.actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusColor: Color {
        switch presentation.state {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .unavailable:
            return .secondary
        case .needsFollowUp:
            return .orange
        case .notDetermined:
            return .secondary
        }
    }
}
