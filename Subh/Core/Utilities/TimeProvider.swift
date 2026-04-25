import Foundation

protocol TimeProviding {
    func now() -> Date
}

struct SystemTimeProvider: TimeProviding {
    func now() -> Date {
        Date()
    }
}
