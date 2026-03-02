import Foundation

enum AppPermissionKind: String, CaseIterable, Identifiable, Sendable {
    case location
    case alarmKit
    case notifications

    var id: String { rawValue }
}

enum AppPermissionState: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
    case needsFollowUp
}

struct PermissionPresentation: Identifiable, Equatable, Sendable {
    let kind: AppPermissionKind
    let state: AppPermissionState
    let title: String
    let statusText: String
    let message: String
    let actionTitle: String?
    let secondaryActionTitle: String?
    let showsProgress: Bool
    let showsSimulatorHint: Bool
    let isBlocking: Bool

    var id: AppPermissionKind { kind }
}
