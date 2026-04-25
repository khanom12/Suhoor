import Foundation

struct WakeTagFilter: Equatable {
    var primaryIntent: FastPrimaryIntent?
    var secondaryTags: Set<FastSecondaryVirtueTag> = []

    var isActive: Bool {
        primaryIntent != nil || !secondaryTags.isEmpty
    }

    var selectedItems: [WakeTagFilterItem] {
        var items: [WakeTagFilterItem] = []
        if let primaryIntent {
            items.append(.primary(primaryIntent))
        }
        items.append(contentsOf: FastIntentEngine.displaySecondaryTags(secondaryTags).map(WakeTagFilterItem.secondary))
        return items
    }

    mutating func clear() {
        primaryIntent = nil
        secondaryTags = []
    }

    mutating func setPrimaryIntent(_ intent: FastPrimaryIntent?) {
        primaryIntent = intent
        normalize()
    }

    mutating func toggleSecondaryTag(_ tag: FastSecondaryVirtueTag) {
        guard allowsSecondaryTag(tag) else { return }
        if secondaryTags.contains(tag) {
            secondaryTags.remove(tag)
        } else {
            secondaryTags.insert(tag)
        }
        normalize()
    }

    var allowsSecondaryTags: Bool {
        guard let primaryIntent else { return true }
        return FastIntentEngine.allowsSecondaryTags(primary: primaryIntent, ruleset: .strict)
    }

    func allowsSecondaryTag(_ tag: FastSecondaryVirtueTag) -> Bool {
        guard allowsSecondaryTags else { return false }
        return secondaryTags.allSatisfy { selected in
            FastIntentEngine.observanceTagsCanCoexist(selected, tag)
        }
    }

    func incompatibilityReason(for tag: FastSecondaryVirtueTag) -> String? {
        guard allowsSecondaryTags else {
            return Strings.AlarmsTab.filterVoluntaryOnlyHelper
        }
        let incompatibleSelections = FastIntentEngine.displaySecondaryTags(secondaryTags).filter { selected in
            !FastIntentEngine.observanceTagsCanCoexist(selected, tag)
        }
        guard !incompatibleSelections.isEmpty else { return nil }
        let titles = incompatibleSelections.map(\.about.title).joined(separator: ", ")
        return Strings.AlarmsTab.filterIncompatibleTagHelper(titles)
    }

    func matches(
        entryPrimaryIntent: FastPrimaryIntent,
        entrySecondaryTags: [FastSecondaryVirtueTag]
    ) -> Bool {
        if let selectedPrimaryIntent = primaryIntent, selectedPrimaryIntent != entryPrimaryIntent {
            return false
        }
        return self.secondaryTags.isSubset(of: Set(entrySecondaryTags))
    }

    private mutating func normalize() {
        guard allowsSecondaryTags else {
            secondaryTags = []
            return
        }
        secondaryTags = FastIntentEngine.compatibleObservanceTags(from: secondaryTags)
    }
}

enum WakeTagFilterItem: Identifiable, Hashable {
    case primary(FastPrimaryIntent)
    case secondary(FastSecondaryVirtueTag)

    var id: String {
        switch self {
        case .primary(let intent):
            return "primary-\(intent.rawValue)"
        case .secondary(let tag):
            return "secondary-\(tag.rawValue)"
        }
    }

    var style: FastTagStyle {
        switch self {
        case .primary(let intent):
            return intent.style
        case .secondary(let tag):
            return tag.style
        }
    }

    var isPrimary: Bool {
        switch self {
        case .primary:
            return true
        case .secondary:
            return false
        }
    }
}
