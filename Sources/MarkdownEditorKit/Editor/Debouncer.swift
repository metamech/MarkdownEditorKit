import Foundation

/// A simple debouncer that delays execution using structured concurrency.
///
/// Each call to ``schedule(_:)`` cancels any pending work and schedules a new
/// execution after the configured delay. Thread-safe when called from a single
/// actor (e.g. `@MainActor`).
@MainActor
final class Debouncer {
    private let duration: Duration
    private var pendingTask: Task<Void, Never>?

    /// Creates a ``Debouncer`` with the given delay duration.
    ///
    /// - Parameter duration: How long to wait before firing the scheduled work.
    init(duration: Duration) {
        self.duration = duration
    }

    /// Cancels any pending work and schedules `action` to run after the configured duration.
    ///
    /// - Parameter action: The closure to execute after the debounce period.
    func schedule(_ action: @MainActor @Sendable @escaping () async -> Void) {
        pendingTask?.cancel()
        pendingTask = Task { [duration] in
            do {
                try await Task.sleep(for: duration)
                try Task.checkCancellation()
            } catch {
                // Cancelled — do not execute.
                return
            }
            await action()
        }
    }

    /// Cancels any pending scheduled work without executing it.
    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }
}
