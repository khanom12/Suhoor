import Foundation

extension Collection where Element == ResolvedScheduledDateProvenance {
    func defaultFastPrimaryIntent() -> FastPrimaryIntent? {
        if contains(where: {
            switch $0.sourceOrigin {
            case .recurringIslamic(let rule):
                return rule == .whiteDays || rule == .mondayThursday
            case .islamicQuickAdd:
                return true
            default:
                return false
            }
        }) {
            return .voluntary
        }
        return nil
    }
}
