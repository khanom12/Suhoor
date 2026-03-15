import SwiftUI

struct WakeListState {
    var loadingSectionIDs: Set<String> = []
    var listSnapshot: WakeListSnapshot = .empty
}
