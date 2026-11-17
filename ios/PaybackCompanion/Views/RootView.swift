import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: CompanionSession

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label(L10n.t(.myDevices), systemImage: "square.grid.2x2")
                }
            ConnectView()
                .tabItem {
                    Label(L10n.t(.companionSection), systemImage: "iphone.radiowaves.left.and.right")
                }
        }
        .preferredColorScheme(nil)
    }
}
