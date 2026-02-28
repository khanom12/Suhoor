import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    #if targetEnvironment(macCatalyst)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Avoid iOS trying to load a non-existent UIScene configuration from Info.plist.
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    #endif
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    #if targetEnvironment(macCatalyst)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        applyFullScreenRestrictions(to: windowScene)
    }

    func windowScene(_ windowScene: UIWindowScene, didUpdateEffectiveGeometry geometry: UIWindowScene.Geometry) {
        applyFullScreenRestrictions(to: windowScene)
    }

    private func applyFullScreenRestrictions(to windowScene: UIWindowScene) {
        guard let restrictions = windowScene.sizeRestrictions else { return }
        let size = windowScene.screen.bounds.size
        restrictions.minimumSize = size
        restrictions.maximumSize = size
        restrictions.allowsFullScreen = true
    }
    #endif
}
