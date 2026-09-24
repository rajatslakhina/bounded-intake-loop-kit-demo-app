import SwiftUI
import BoundedIntakeLoop

/// Configuration that belongs to the **app**, not to the library.
///
/// Which currency an intake screen runs under is a product decision, so it is
/// compiled in here and threaded through `IntakeDemoView` into the loop's
/// `DeterministicIntake` and into the pinned eval expectations. The library
/// takes it as a parameter and never assumes one — that split is the same seam
/// the model provider sits behind, applied to a much smaller decision.
enum DemoConfiguration {
    static let currencyCode = "USD"
}

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            IntakeDemoView(currencyCode: DemoConfiguration.currencyCode)
        }
    }
}
