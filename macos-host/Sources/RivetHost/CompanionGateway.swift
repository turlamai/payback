import Foundation
import RivetDevice
import RivetDeviceAppleSecurity
import RivetDeviceAppleTransport
import RivetDeviceSession
import RivetRuntime

// Product binding for the Rivet device channel (issue #63): the desktop
// gateway terminates authenticated companion sessions and applies the
// companion scope before any RPC reaches the embedded backend. Network
// exposure stays off until the user enables it in Settings
// (docs/network-device-channel.md invariant 4); discovery is never
// authentication; pairing requires explicit approval on both sides.

/// Channel configuration constants. A file-private namespace keeps them
/// readable from the @Sendable handler closures the framework calls on its
/// own executors.
private enum CompanionConfig {
    static let applicationID = "site.jrtx.payback"
    static let pairingService = "site.jrtx.payback.device-pairing"
    static let serviceName = "Payback"
    static let scopeName = "companion"
}

@MainActor
final class CompanionManager: ObservableObject {
    static let applicationID = CompanionConfig.applicationID
    static let pairingService = CompanionConfig.pairingService
    static let serviceName = CompanionConfig.serviceName
    static let scopeName = CompanionConfig.scopeName

    /// The companion surface: the same user-data RPCs the desktop UI drives,
    /// nothing else. Keep in lockstep with rivet.rktd `device-rpcs` — the
    /// gateway scope is the authoritative server-side check regardless of
    /// what any client advertises.
    static let scopeRPCs: Set<String> = [
        "load-all", "trash-list", "add-device", "update-device",
        "delete-device", "restore-device", "sync-state"
    ]

    struct PairingPrompt: Identifiable, Equatable {
        let attemptID: UUID
        let code: String
        let expiresAt: Date
        var id: String { attemptID.uuidString }
    }

    @Published private(set) var enabled = false
    @Published private(set) var pairingWindowOpen = false
    /// shown in Settings for the manual pairing flow until the QR path
    /// exists (issue #63)
    @Published private(set) var activeWindowID: UUID?
    @Published private(set) var pairingPrompt: PairingPrompt?
    @Published private(set) var pairedDevices: [RivetDevicePairedDevice] = []
    @Published private(set) var fingerprintHex: String?
    @Published private(set) var activeSessionCount = 0
    @Published var lastError: String?

    private var listener: RivetDeviceAppleListener?
    private var coordinator: RivetDevicePairingCoordinator?
    private var gateway: RivetDeviceGateway?
    private var pairingWindowTask: Task<Void, Never>?
    private var pairingWindowID: UUID?
    private var sessionTasks: [Task<Void, Never>] = []
    /// pairing prompts keyed by attempt, each holding its own session host
    /// so approval reaches exactly the connection that asked
    private var pendingHosts: [UUID: RivetDeviceAppleSessionHost] = [:]
    private var backendClient: (any RivetRPCClient)?
    private let store: RivetDeviceApplePairingStore?

    init() {
        // a Keychain failure must not block app startup; enabling the
        // companion later reports the error honestly
        store = try? RivetDeviceApplePairingStore(service: Self.pairingService)
        Task { await refreshPairedDevices() }
    }

    func attach(client: any RivetRPCClient) {
        backendClient = client
    }

    // ---------- enable / disable ----------

    func setEnabled(_ on: Bool) {
        if on { enable() } else { disable() }
    }

    private func enable() {
        guard let backendClient else {
            lastError = L10n.t(.backendError)
            return
        }
        guard let store else {
            lastError = L10n.t(.companionFailed)
            return
        }
        Task {
            do {
                let gateway = RivetDeviceGateway(
                    host: RivetDeviceRVT1BackendHost(client: backendClient))
                let coordinator = RivetDevicePairingCoordinator(store: store)
                let listener = try RivetDeviceAppleListener(
                    applicationID: Self.applicationID,
                    serviceName: Self.serviceName
                ) { connection in
                    await self.accept(connection: connection)
                }
                let snapshot = try await listener.enable()
                self.gateway = gateway
                self.coordinator = coordinator
                self.listener = listener
                self.enabled = true
                self.lastError = nil
                if let fingerprint = snapshot.serverFingerprint {
                    fingerprintHex = fingerprint.map {
                        String(format: "%02x", $0)
                    }.joined()
                }
                await refreshPairedDevices()
            } catch {
                self.enabled = false
                self.lastError = Self.cleanError(error)
            }
        }
    }

    func disable() {
        Task {
            closePairingWindow()
            for task in sessionTasks { task.cancel() }
            sessionTasks.removeAll()
            pendingHosts.removeAll()
            await gateway?.closeAllSessions()
            await listener?.disable()
            await listener?.terminate()
            listener = nil
            coordinator = nil
            gateway = nil
            enabled = false
            pairingPrompt = nil
            activeSessionCount = 0
            await refreshPairedDevices()
        }
    }

    // ---------- pairing ----------

    func openPairingWindow() {
        Task {
            do {
                guard let listener, let coordinator else { return }
                guard let fingerprint = await listener.snapshot().serverFingerprint else {
                    lastError = L10n.t(.companionFailed)
                    return
                }
                let window = try await coordinator.openWindow(
                    applicationID: Self.applicationID,
                    serverFingerprint: fingerprint)
                try await listener.setPairingWindowOpen(true)
                pairingWindowID = window.id
                activeWindowID = window.id
                pairingWindowOpen = true
                pairingWindowTask?.cancel()
                pairingWindowTask = Task { [weak self] in
                    let seconds = window.expiresAt.timeIntervalSinceNow + 1
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    if !Task.isCancelled { self?.closePairingWindow() }
                }
            } catch {
                lastError = Self.cleanError(error)
            }
        }
    }

    func closePairingWindow() {
        pairingWindowTask?.cancel()
        pairingWindowTask = nil
        if let windowID = pairingWindowID {
            Task {
                try? await coordinator?.cancelWindow(windowID: windowID)
            }
        }
        pairingWindowID = nil
        activeWindowID = nil
        guard let listener else {
            pairingWindowOpen = false
            return
        }
        Task {
            try? await listener.setPairingWindowOpen(false)
            pairingWindowOpen = false
        }
    }

    func approvePairing(_ approved: Bool) {
        guard let prompt = pairingPrompt,
              let host = pendingHosts[prompt.attemptID] else { return }
        Task {
            do {
                if approved {
                    try await host.confirmPairing(
                        grantedScopeNames: [Self.scopeName])
                } else {
                    try await host.rejectPairing()
                }
            } catch {
                lastError = Self.cleanError(error)
            }
            pendingHosts.removeValue(forKey: prompt.attemptID)
            pairingPrompt = nil
            await refreshPairedDevices()
        }
    }

    func removePairedDevice(_ device: RivetDevicePairedDevice) {
        Task {
            // credential first, sessions second (docs/device-communication.md)
            try? await store?.remove(deviceID: device.id)
            await gateway?.revokeSessions(deviceID: device.id)
            await refreshPairedDevices()
        }
    }

    func refreshPairedDevices() async {
        do {
            pairedDevices = try await store?.pairedDevices() ?? []
        } catch {
            // the list is best-effort; a locked Keychain shows an empty list
            pairedDevices = []
        }
    }

    // ---------- connection lifecycle ----------

    private func accept(connection: RivetDeviceAppleConnection) {
        Task {
            guard let coordinator, let gateway, let store else { return }
            guard let fingerprint = await listener?.snapshot().serverFingerprint,
                  fingerprint.count == rivetDeviceFingerprintSize else {
                return
            }
            do {
                // the prompt handler needs its own session host, which does
                // not exist until the initializer returns — hand it a box
                let box = HostBox()
                let host = try RivetDeviceAppleSessionHost(
                    connection: connection,
                    serverFactory: { startedAt in
                        try RivetDeviceSessionServer(
                            applicationID: CompanionConfig.applicationID,
                            serverFingerprint: fingerprint,
                            store: store,
                            pairingCoordinator: coordinator,
                            startedAt: startedAt)
                    },
                    pairingPromptHandler: { [weak self] prompt in
                        await self?.present(prompt: prompt, box: box)
                    },
                    applicationHandler: { acceptance, connection in
                        try await self.serve(acceptance: acceptance,
                                         connection: connection)
                    })
                box.value = host
                let task = Task {
                    do {
                        try await host.run()
                    } catch {
                        self.reportSessionFailure(host: host, error: error)
                    }
                    await self.finishSessionHost(host)
                }
                sessionTasks.append(task)
            } catch {
                lastError = Self.cleanError(error)
            }
        }
    }

    /// the session host is an actor (a reference type); the prompt handler
    /// receives it through this box because the host does not exist while
    /// its own initializer runs
    private final class HostBox: @unchecked Sendable {
        weak var value: RivetDeviceAppleSessionHost?
    }

    private func present(prompt: RivetDeviceApplePairingPrompt,
                         box: HostBox) {
        guard let host = box.value else { return }
        pendingHosts[prompt.attemptID] = host
        pairingPrompt = PairingPrompt(attemptID: prompt.attemptID,
                                      code: prompt.verificationCode,
                                      expiresAt: prompt.expiresAt)
    }

    /// Accepted session: open a scoped gateway session and run the RVT1
    /// server until the companion disconnects. The scope is the only
    /// authority the companion ever receives.
    private func serve(acceptance: RivetDeviceSessionAcceptance,
                       connection: RivetDeviceAppleConnection) async throws {
        guard let gateway else { return }
        let session = try await gateway.openSession(
            pairedDeviceID: acceptance.deviceID,
            scopes: [RivetDeviceScope(name: Self.scopeName,
                                      rpcs: Self.scopeRPCs)])
        activeSessionCount += 1
        defer { activeSessionCount = max(activeSessionCount - 1, 0) }
        let server = RivetDeviceAppleRVT1GatewayServer(
            connection: connection,
            gateway: gateway,
            session: session)
        try await server.run()
    }

    private func reportSessionFailure(host: RivetDeviceAppleSessionHost,
                                      error: Error) {
        // a rejected pairing surfaces through the prompt flow; only report
        // failures for connections we were not already tracking as prompts
        if !pendingHosts.values.contains(where: { $0 === host }) {
            lastError = Self.cleanError(error)
        }
    }

    private func finishSessionHost(_ host: RivetDeviceAppleSessionHost) async {
        if let attemptID = pendingHosts.first(where: { $0.value === host })?.key {
            pendingHosts.removeValue(forKey: attemptID)
            if pairingPrompt?.attemptID == attemptID {
                pairingPrompt = nil
            }
        }
    }

    private static func cleanError(_ error: Error) -> String {
        let text = "\(error)"
        if let range = text.range(of: "error: ") {
            return String(text[range.upperBound...])
        }
        return text
    }
}
