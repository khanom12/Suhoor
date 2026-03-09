import SwiftUI

struct WakeListState {
    var selectedSchedule: DaySchedule?
    var loadingSectionIDs: Set<String> = []
    var listSnapshot: WakeListSnapshot = .empty
}
