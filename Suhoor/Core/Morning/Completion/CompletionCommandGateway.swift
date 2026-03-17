import Foundation

@MainActor
final class CompletionCommandGateway {
    private let repository: any CompletionRepository

    init(
        repository: any CompletionRepository
    ) {
        self.repository = repository
    }

    @discardableResult
    func perform(
        _ intent: CompletionEditIntent,
        source: CompletionMutationSource,
        now: Date = Date()
    ) -> CompletionMutationResult {
        repository.perform(intent, source: source, now: now)
    }
}
