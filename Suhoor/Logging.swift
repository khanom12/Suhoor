import Foundation
import os

enum Logging {
    static let scheduler = Logger(subsystem: "com.suhoor.app", category: "scheduler")
    static let location = Logger(subsystem: "com.suhoor.app", category: "location")
    static let diagnostics = Logger(subsystem: "com.suhoor.app", category: "diagnostics")
    static let notifications = Logger(subsystem: "com.suhoor.app", category: "notifications")
}
