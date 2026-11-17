import SwiftUI
import RivetDevice
import RivetDeviceAppleCompanionUI
import RivetDeviceAppleTransport

// Connect tab: discovery, pairing (six-digit code confirmation on both
// sides), reconnect, and saved pairings. The coordinator plumbing is the
// framework's RivetDeviceAppleCompanionModel; this surface renders it in
// Payback's language and adds the manual pairing-window ID field (the QR
// path is designed but not built — declared UX delta, issue #63).

struct ConnectView: View {
    @EnvironmentObject private var session: CompanionSession
    @EnvironmentObject private var model: RivetDeviceAppleCompanionModel

    var body: some View {
        NavigationStack {
            List {
                statusSection
                if session.companion == nil {
                    Section {
                        Text(L10n.t(.companionFailed))
                            .foregroundStyle(PaybackTheme.danger)
                    }
                }
                discoverySection
                pairedSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(PaybackTheme.paper)
            .navigationTitle(L10n.t(.companionSection))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await model.refreshPairedDevices()
                session.startBrowsing()
            }
            .onDisappear {
                session.stopBrowsing()
            }
        }
    }

    private var statusSection: some View {
        Section(L10n.t(.companionSessionHeader)) {
            HStack(spacing: 10) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                Text(session.phase.title)
                    .font(.system(size: 15))
                Spacer()
                if case .connected = session.phase {
                    Button(L10n.t(.companionDisconnect)) {
                        session.disconnect()
                    }
                    .controlSize(.small)
                }
            }
            if case .awaitingCode = session.phase, let code = model.pairingCode {
                VStack(spacing: 8) {
                    Text(code.verificationCode)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                    Text(L10n.t(.companionPromptBody))
                        .font(.caption)
                        .foregroundStyle(PaybackTheme.muted)
                        .multilineTextAlignment(.center)
                    HStack {
                        Button(L10n.t(.companionReject), role: .destructive) {
                            session.confirmPairing(false)
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button(L10n.t(.companionApprove)) {
                            session.confirmPairing(true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PaybackTheme.earn)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var statusIcon: String {
        switch session.phase {
        case .connected: return "checkmark.shield"
        case .failed: return "exclamationmark.triangle"
        case .connecting, .awaitingCode: return "hourglass"
        default: return "iphone.slash"
        }
    }

    private var statusColor: Color {
        switch session.phase {
        case .connected: return PaybackTheme.earn
        case .failed: return PaybackTheme.danger
        default: return PaybackTheme.muted
        }
    }

    @ViewBuilder
    private var discoverySection: some View {
        Section(L10n.t(.companionNearby)) {
            HStack {
                Button {
                    if model.isBrowsing {
                        session.stopBrowsing()
                    } else {
                        session.startBrowsing()
                    }
                } label: {
                    Label(model.isBrowsing
                          ? L10n.t(.companionStopScan)
                          : L10n.t(.companionScan),
                          systemImage: model.isBrowsing ? "stop.circle" : "magnifyingglass")
                }
                .disabled(session.companion == nil)
                Spacer()
                if model.isBrowsing {
                    ProgressView().controlSize(.small)
                }
            }
            if model.discoveries.isEmpty {
                Text(L10n.t(.companionNoDevices))
                    .font(.caption)
                    .foregroundStyle(PaybackTheme.muted)
            }
            ForEach(model.discoveries, id: \.endpoint) { discovery in
                VStack(alignment: .leading, spacing: 8) {
                    Text(discovery.serviceName)
                        .font(.system(size: 15, weight: .semibold))
                    Text(discovery.pairingWindowOpen
                         ? L10n.t(.companionWindowOpen)
                         : L10n.t(.companionWindowClosed))
                        .font(.caption)
                        .foregroundStyle(discovery.pairingWindowOpen
                                         ? PaybackTheme.earn : PaybackTheme.muted)
                    if discovery.pairingWindowOpen {
                        pairingControls(for: discovery)
                    } else if !model.pairedDevices.isEmpty {
                        reconnectMenu(for: discovery)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func pairingControls(for discovery: RivetDeviceAppleBonjourDiscovery)
        -> some View {
        TextField(L10n.t(.companionWindowIDField), text: $session.pairingWindowIDText)
            .font(.caption.monospaced())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        HStack {
            Button {
                if let windowID = session.manualWindowID {
                    model.pair(discovery, windowID: windowID)
                }
            } label: {
                Label(L10n.t(.companionPair), systemImage: "link")
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.manualWindowID == nil)
            Spacer()
        }
    }

    private func reconnectMenu(for discovery: RivetDeviceAppleBonjourDiscovery)
        -> some View {
        Menu {
            ForEach(model.pairedDevices, id: \.id) { device in
                Button(device.name) {
                    model.reconnect(discovery, deviceID: device.id)
                }
            }
        } label: {
            Label(L10n.t(.companionReconnect), systemImage: "arrow.triangle.2.circlepath")
        }
    }

    @ViewBuilder
    private var pairedSection: some View {
        Section(L10n.t(.companionPairedLabel)) {
            if model.pairedDevices.isEmpty {
                Text(L10n.t(.companionEmptyPaired))
                    .font(.caption)
                    .foregroundStyle(PaybackTheme.muted)
            }
            ForEach(model.pairedDevices, id: \.id) { device in
                HStack(spacing: 10) {
                    Image(systemName: "iphone")
                        .foregroundStyle(PaybackTheme.muted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.system(size: 15))
                        Text(device.applicationID)
                            .font(.caption2)
                            .foregroundStyle(PaybackTheme.muted)
                    }
                    Spacer()
                    Button(L10n.t(.companionRemove), role: .destructive) {
                        model.removePairing(deviceID: device.id)
                    }
                    .controlSize(.small)
                }
            }
        }
    }
}
