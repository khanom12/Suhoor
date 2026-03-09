import SwiftUI

struct WakeListState {
    var selectedSchedule: DaySchedule?
    var showTagFilterSheet = false
    var editMode: EditMode = .inactive
    var sectionCollapseOverrides: [String: Bool] = [:]
    var loadingSectionIDs: Set<String> = []
    var listSnapshot: WakeListSnapshot = .empty
    var tagFilter = AlarmTagFilter()
    var pendingSeriesDeleteEntry: WakeRowEntry?
    var pendingRamadanEntry: WakeRowEntry?
    var pinnedNextWakeEntryIDs: [String] = []
    var animatePinnedNextWakeUpdates = false
}
