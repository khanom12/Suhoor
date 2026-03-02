import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Group {
                if scheduleManager.showsHome {
                    AlarmsHomeView()
                } else {
                    OnboardingView()
                }
            }
        }
        // Force the root container to occupy the full screen to avoid a centered "panel" layout on iPhone.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .modifier(RootSizeGuard())
    }
}


extension Notification.Name {
    static let switchToAlarmTab = Notification.Name("SwitchToAlarmTab")
    static let switchToScheduleTab = Notification.Name("SwitchToScheduleTab")
    static let switchToSettingsTab = Notification.Name("SwitchToSettingsTab")
}

#if DEBUG
private struct RootSizeGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { logIfNeeded(size: proxy.size) }
                        .onChange(of: proxy.size) { _, newSize in
                            logIfNeeded(size: newSize)
                        }
                }
            )
    }

    private func logIfNeeded(size: CGSize) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        let screenSize = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
            .bounds
            .size ?? size
        if size.width + 1 < screenSize.width || size.height + 1 < screenSize.height {
            print("Root view is smaller than screen on iPhone: \(size) vs \(screenSize)")
        }
    }
}
#else
private struct RootSizeGuard: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#endif
