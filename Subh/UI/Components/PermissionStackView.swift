import SwiftUI

struct PermissionStackView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let kinds: [AppPermissionKind]
    let refreshKey: String
    let showOnlyBlocking: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingComfortable) {
            ForEach(filteredPresentations) { presentation in
                PermissionCardView(
                    presentation: presentation,
                    action: presentation.actionTitle == nil ? nil : {
                        Task { await handleAction(for: presentation) }
                    }
                )
            }
        }
        .id(refreshKey)
    }

    private var filteredPresentations: [PermissionPresentation] {
        if showOnlyBlocking {
            return presentations.filter(\.isBlocking)
        }
        return presentations
    }

    private func handleAction(for presentation: PermissionPresentation) async {
        switch presentation.state {
        case .notDetermined, .needsFollowUp:
            _ = await scheduleManager.requestPermission(presentation.kind)
        case .denied, .restricted:
            onOpenSettings()
        case .authorized, .unavailable:
            break
        }
    }

    private var presentations: [PermissionPresentation] {
        kinds.compactMap { scheduleManager.permissionSnapshot.presentations[$0] }
    }
}
