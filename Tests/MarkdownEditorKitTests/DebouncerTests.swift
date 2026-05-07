import Foundation
import Testing

@testable import MarkdownEditorKit

@Suite("Debouncer")
@MainActor
struct DebouncerTests {
    // MARK: - Fires after delay

    @Test("single schedule fires after delay")
    func singleScheduleFires() async throws {
        let debouncer = Debouncer(duration: .milliseconds(50))
        var callCount = 0

        debouncer.schedule {
            callCount += 1
        }

        // Before delay: should not have fired yet.
        #expect(callCount == 0)

        // Wait long enough for the action to run.
        try await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 1)
    }

    // MARK: - Rapid-fire collapses to one execution

    @Test("rapid-fire schedule calls collapse to one execution")
    func rapidFireCollapsesToOne() async throws {
        let debouncer = Debouncer(duration: .milliseconds(100))
        var callCount = 0

        // Schedule five times in quick succession.
        for _ in 0..<5 {
            debouncer.schedule {
                callCount += 1
            }
        }

        // Wait for the debounce window to pass.
        try await Task.sleep(for: .milliseconds(300))

        // Only the last scheduled action should have fired once.
        #expect(callCount == 1)
    }

    // MARK: - Cancel prevents execution

    @Test("cancel prevents scheduled action from running")
    func cancelPreventsExecution() async throws {
        let debouncer = Debouncer(duration: .milliseconds(100))
        var callCount = 0

        debouncer.schedule {
            callCount += 1
        }

        debouncer.cancel()

        // Wait longer than the debounce delay to confirm nothing fires.
        try await Task.sleep(for: .milliseconds(300))
        #expect(callCount == 0)
    }

    // MARK: - Cancel-and-reschedule: only the rescheduled action fires

    @Test("cancel then reschedule causes new action to fire")
    func cancelThenReschedule() async throws {
        let debouncer = Debouncer(duration: .milliseconds(50))
        var firstCount = 0
        var secondCount = 0

        debouncer.schedule {
            firstCount += 1
        }
        debouncer.cancel()

        debouncer.schedule {
            secondCount += 1
        }

        try await Task.sleep(for: .milliseconds(200))
        #expect(firstCount == 0)
        #expect(secondCount == 1)
    }

    // MARK: - Second schedule cancels first

    @Test("second schedule cancels first and only second fires")
    func secondScheduleCancelsFirst() async throws {
        let debouncer = Debouncer(duration: .milliseconds(100))
        var firstFired = false
        var secondFired = false

        debouncer.schedule {
            firstFired = true
        }

        // Almost immediately reschedule before the first fires.
        try await Task.sleep(for: .milliseconds(25))

        debouncer.schedule {
            secondFired = true
        }

        // Wait for second to fire.
        try await Task.sleep(for: .milliseconds(250))

        #expect(firstFired == false)
        #expect(secondFired == true)
    }

    // MARK: - Multiple cancel calls are idempotent

    @Test("multiple cancel calls do not crash")
    func multipleCancelsAreIdempotent() async throws {
        let debouncer = Debouncer(duration: .milliseconds(50))
        var callCount = 0

        debouncer.schedule {
            callCount += 1
        }

        debouncer.cancel()
        debouncer.cancel()
        debouncer.cancel()

        try await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 0)
    }
}
