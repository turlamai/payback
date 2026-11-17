import Foundation
import RivetDevice
import RivetDeviceAppleCompanion
import RivetDeviceAppleTransport
import SwiftUI
import UIKit

// Companion session orchestration: pairing + reconnect through the
// RivetDeviceAppleCompanion coordinator, and the accepted RVT1 session that
// serves the library UI. The application handler keeps the client alive for
// the whole connection; reads and writes all go through the desktop gateway.

@MainActor
final class CompanionSession: ObservableObject {
    enum Phase: Equatable {
        case idle
        case connecting
        case awaitingCode
        case connected
        case failed(String)

        var title: String {
            switch self {
            case .idle: return L10n.t(.companionIdle)
            case .connecting: return L10n.t(.companionConnecting)
            case .awaitingCode: return L10n.t(.companionConfirmCode)
            case .connected: return L10n.t(.companionConnected)
            case .failed(let message): return message
            }
        }
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var document: LoadAllDocument?
    @Published private(set) var trash: [Device] = []
    @Published private(set) var isBrowsing = false
    @Published var pairingWindowIDText = ""

    /// nil when the Keychain-backed coordinator could not start (presented
    /// as an unavailable pairing surface, never a crash)
    let companion: RivetDeviceAppleCompanion?
    private var client: RivetDeviceAppleRVT1Client?
    private var sessionTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?

    init() {
        companion = try? RivetDeviceAppleCompanion.usingKeychain(
            configuration: RivetDeviceAppleCompanionConfiguration(
                applicationID: "site.jrtx.payback",
                deviceName: UIDevice.current.name),
            service: "site.jrtx.payback.companion")
        startEventLoop()
    }

    /// a companion shell for the boot-failure path; pairing stays
    /// unavailable but the app runs — credentials never persist, so the
    /// connect screen degrades to "unavailable" honestly
    static func dormantCompanion() -> RivetDeviceAppleCompanion {
        let configuration = try! RivetDeviceAppleCompanionConfiguration(
            applicationID: "site.jrtx.payback",
            deviceName: "Payback")
        return (try? RivetDeviceAppleCompanion(
            configuration: configuration,
            pairingStore: DormantPairingStore()))!
    }

    private func startEventLoop() {
        guard let companion else { return }
        let events = companion.events
        eventTask = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { return }
                await self?.consume(event)
            }
        }
    }

    private func consume(_ event: RivetDeviceAppleCompanionEvent) {
        switch event {
        case .discovery(.ready):
            isBrowsing = true
            if phase == .idle { phase = .idle }
        case .discovery(.failed), .discovery(.cancelled):
            isBrowsing = false
        case .pairingCode:
            phase = .awaitingCode
        case .connected:
            phase = .connected
            Task { await refresh() }
        case .sessionEnded, .sessionFailed:
            client = nil
            if phase == .connected { phase = .idle }
        default:
            break
        }
    }

    // ---------- pairing / connection ----------

    func startBrowsing() {
        guard let companion else { return }
        isBrowsing = true
        Task {
            try? await companion.startBrowsing()
        }
    }

    func stopBrowsing() {
        guard let companion else { return }
        isBrowsing = false
        Task {
            await companion.stopBrowsing()
        }
    }

    /// Pairing requires the desktop's explicit pairing-window ID. The
    /// designed path is a desktop QR code; until that exists the desktop
    /// shows the ID and the user pastes it here (declared UX delta, #63).
    var manualWindowID: UUID? {
        UUID(uuidString: pairingWindowIDText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func confirmPairing(_ confirmed: Bool) {
        guard let companion else { return }
        Task {
            try? await companion.confirmPairing(confirmed)
            if confirmed {
                phase = .connecting
            } else if phase == .awaitingCode {
                phase = .idle
            }
        }
    }

    func cancelSession() {
        guard let companion else { return }
        Task {
            await companion.cancelSession()
        }
    }

    func disconnect() {
        guard let companion else { return }
        Task {
            await companion.cancelSession()
        }
    }

    func pairedDevices() async -> [RivetDevicePairedDevice] {
        guard let companion else { return [] }
        return (try? await companion.pairedDevices()) ?? []
    }

    func removePairing(deviceID: UUID) {
        guard let companion else { return }
        Task {
            try? await companion.removePairing(deviceID: deviceID)
        }
    }

    /// The companion framework calls this once per accepted session; the
    /// handler owns the post-RVD1 RVT1 surface and must stay alive for the
    /// connection's lifetime (that is what run() gives us).
    func applicationHandler() -> RivetDeviceAppleCompanion.ApplicationHandler {
        { acceptance, connection in
            let client = RivetDeviceAppleRVT1Client(connection: connection)
            await self.attach(client: client)
            try await client.run()
            await self.detach(client: client)
        }
    }

    private func attach(client: RivetDeviceAppleRVT1Client) {
        self.client = client
        Task { await refresh() }
    }

    private func detach(client: RivetDeviceAppleRVT1Client) {
        if self.client === client {
            self.client = nil
        }
    }

    // ---------- data ----------

    /// no live RVT1 session: reads are unavailable and the library shows
    /// the connect guidance
    var clientInactive: Bool { client == nil }

    func refresh() async {
        guard let client else { return }
        do {
            document = try await client.loadAll()
        } catch {
            phase = .failed(Self.cleanError(error))
        }
    }

    func loadTrash() async {
        guard let client else { return }
        trash = (try? await client.trashList()) ?? []
    }

    func delete(_ device: Device) async {
        guard let client else { return }
        do {
            try await client.deleteDevice(id: device.id)
            await refresh()
        } catch {
            phase = .failed(Self.cleanError(error))
        }
    }

    func restore(_ device: Device) async {
        guard let client else { return }
        do {
            try await client.restoreDevice(id: device.id)
            await refresh()
        } catch {
            phase = .failed(Self.cleanError(error))
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

/// Volatile store for the dormant companion shell: the boot-failure path
/// must never crash, and credentials that cannot persist must not pretend
/// to. Pairing through this shell simply does not survive the session.
struct DormantPairingStore: RivetDevicePairingStore {
    func save(_ pairing: RivetDeviceStoredPairing) async throws {}
    func load(deviceID: UUID) async throws -> RivetDeviceStoredPairing? { nil }
    func pairedDevices() async throws -> [RivetDevicePairedDevice] { [] }
    func remove(deviceID: UUID) async throws {}
}
