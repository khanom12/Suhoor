import SwiftUI

struct PermissionStackView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let kinds: [AppPermissionKind]
    let refreshKey: String
    let showOnlyBlocking: Bool
    let onOpenSettings: () -> Void

    @State private var presentations: [PermissionPresentation] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(filteredPresentations) { presentation in
                PermissionCardView(
                    presentation: presentation,
                    action: presentation.actionTitle == nil ? nil : {
                        Task { await handleAction(for: presentation) }
                    }
                )
            }
        }
        .task {
            await refresh()
        }
        .task(id: refreshKey) {
            await refresh()
        }
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
        await refresh()
    }

    private func refresh() async {
        var updated: [PermissionPresentation] = []
        for kind in kinds {
            updated.append(await scheduleManager.permissionPresentation(for: kind))
        }
        presentations = updated
        await scheduleManager.refreshPermissionSummary()
    }
}
