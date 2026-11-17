import SwiftUI
import RivetDeviceAppleCompanionUI

// Payback companion (iOS / iPadOS, issue #63): an authenticated client of
// the desktop engine over the Rivet device channel. The prototype's
// responsive rules are the layout contract — compact width stacks list and
// detail with a back button (design/DESIGN.md 768px rule); regular width
// shows the split.

@main
struct PaybackCompanionApp: App {
    @StateObject private var session: CompanionSession
    @StateObject private var companionModel: RivetDeviceAppleCompanionModel

    init() {
        let session = CompanionSession()
        _session = StateObject(wrappedValue: session)
        if let companion = session.companion {
            _companionModel = StateObject(wrappedValue: RivetDeviceAppleCompanionModel(
                companion: companion,
                applicationHandler: session.applicationHandler()))
        } else {
            // a Keychain failure at launch must not crash the app; the
            // connect screen presents the unavailable state
            _companionModel = StateObject(wrappedValue: RivetDeviceAppleCompanionModel(
                companion: CompanionSession.dormantCompanion(),
                applicationHandler: { _, _ in }))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(companionModel)
                .tint(PaybackTheme.accent)
        }
    }
}
