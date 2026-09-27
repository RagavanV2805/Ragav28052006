import Foundation

/// Detects UI-test launches so side effects (notification prompts, stale
/// stores) never interfere with deterministic UI tests.
enum UITestMode {
    static let flag = "-uitest"

    static var isActive: Bool {
        CommandLine.arguments.contains(flag) || ProcessInfo.processInfo.arguments.contains(flag)
    }
}
