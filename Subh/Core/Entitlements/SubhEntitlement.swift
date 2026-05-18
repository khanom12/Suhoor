import Combine
import Foundation

enum SubhEntitlementTier: String, Codable, CaseIterable, Identifiable {
    case free
    case plus
    case complete
    case completeLifetime
    case completeTrial
    case ramadanPreview

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .plus:
            return "Plus"
        case .complete:
            return "Complete"
        case .completeLifetime:
            return "Complete Lifetime"
        case .completeTrial:
            return "Complete Trial"
        case .ramadanPreview:
            return "Ramadan Preview"
        }
    }
}

enum SubhFeatureGate: Hashable {
    case monthPlanning
    case suhoorPlanning
    case monthlyFajrcast
}

struct SubhEntitlementSnapshot: Equatable {
    let tier: SubhEntitlementTier
    let isTemporary: Bool

    static let free = SubhEntitlementSnapshot(tier: .free)
    static let plus = SubhEntitlementSnapshot(tier: .plus)
    static let complete = SubhEntitlementSnapshot(tier: .complete)
    static let completeTrial = SubhEntitlementSnapshot(tier: .completeTrial, isTemporary: true)

    init(tier: SubhEntitlementTier, isTemporary: Bool? = nil) {
        self.tier = tier
        self.isTemporary = isTemporary ?? {
            switch tier {
            case .completeTrial, .ramadanPreview:
                return true
            case .free, .plus, .complete, .completeLifetime:
                return false
            }
        }()
    }

    var displayName: String {
        tier.displayName
    }

    func allows(_ gate: SubhFeatureGate) -> Bool {
        switch gate {
        case .monthPlanning:
            return tier == .plus || allowsCompleteFeatures
        case .suhoorPlanning:
            return allowsCompleteFeatures || tier == .ramadanPreview
        case .monthlyFajrcast:
            return allowsCompleteFeatures
        }
    }

    private var allowsCompleteFeatures: Bool {
        switch tier {
        case .complete, .completeLifetime, .completeTrial:
            return true
        case .free, .plus, .ramadanPreview:
            return false
        }
    }
}

@MainActor
final class SubhEntitlementStore: ObservableObject {
    static let shared = SubhEntitlementStore()

    private static let defaultsKey = "Subh.EntitlementTier"

    @Published private(set) var snapshot: SubhEntitlementSnapshot

    init(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        let rawTier = environment["SUBH_ENTITLEMENT_TIER"]
            ?? defaults.string(forKey: Self.defaultsKey)
        let tier = rawTier.flatMap(SubhEntitlementTier.init(rawValue:)) ?? .free
        self.snapshot = SubhEntitlementSnapshot(tier: tier)
    }

    func updateForTesting(_ snapshot: SubhEntitlementSnapshot) {
        self.snapshot = snapshot
    }
}
