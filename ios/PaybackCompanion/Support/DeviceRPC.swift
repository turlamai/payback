import Foundation
import RivetDevice
import RivetDeviceAppleTransport
import RivetRuntime

// Typed engine surface for the network companion. The generated
// RivetDeviceClient targets the JSON-envelope transport (the
// WatchConnectivity relay); the network device channel speaks RVT1 value
// frames, so the companion drives the engine's device surface through this
// adapter. Keep the RPC names in lockstep with rivet.rktd `device-rpcs` and
// the desktop companion scope — the gateway is the authoritative check.

extension RivetDeviceAppleRVT1Client {
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: payload plumbing

    private static func bytes(_ value: RivetValue) throws -> Data {
        guard case .bytes(let data) = value else {
            throw CompanionError.unexpectedResponse
        }
        return data
    }

    private static func arguments(_ data: Data) -> [RivetValue] {
        [.bytes(data)]
    }

    enum CompanionError: Error {
        case unexpectedResponse
    }

    // MARK: reads

    func loadAll() async throws -> LoadAllDocument {
        try Self.decoder.decode(LoadAllDocument.self,
                                from: try Self.bytes(try await call("load-all")))
    }

    func trashList() async throws -> [Device] {
        let document = try Self.decoder.decode(TrashDocument.self,
                                               from: try Self.bytes(try await call("trash-list")))
        return document.trash
    }

    func syncState() async throws -> Int64 {
        let document = try Self.decoder.decode(SyncState.self,
                                               from: try Self.bytes(try await call("sync-state")))
        return document.revision
    }

    // MARK: writes

    @discardableResult
    func addDevice(_ draft: DeviceDraft) async throws -> Device {
        let payload = try Self.encoder.encode(draft)
        let created = try Self.bytes(try await call("add-device",
                                                    arguments: Self.arguments(payload)))
        return try Self.decoder.decode(Device.self, from: created)
    }

    @discardableResult
    func updateDevice(_ draft: DeviceDraft, id: String) async throws -> Device {
        var object = try JSONSerialization.jsonObject(with: Self.encoder.encode(draft))
        if var dictionary = object as? [String: Any] {
            dictionary["id"] = id
            object = dictionary
        }
        let payload = try JSONSerialization.data(withJSONObject: object)
        let updated = try Self.bytes(try await call("update-device",
                                                    arguments: Self.arguments(payload)))
        return try Self.decoder.decode(Device.self, from: updated)
    }

    func deleteDevice(id: String) async throws {
        _ = try await call("delete-device", arguments: [.string(id)])
    }

    @discardableResult
    func restoreDevice(id: String) async throws -> Device {
        let restored = try Self.bytes(try await call("restore-device",
                                                     arguments: [.string(id)]))
        return try Self.decoder.decode(Device.self, from: restored)
    }
}

// MARK: - summary helpers (display arithmetic over engine-computed values)

extension Device {
    /// goal-met state for the row dot and detail badge
    var isGoalMet: Bool { computed.paidBack }

    var dailyCostText: String {
        Money.perDay(computed.costPerDayMinor, code: currency)
    }
}

extension Summary {
    /// the sidebar summary's default-currency group (#23: mixed portfolios
    /// never share a money value)
    func group(for currency: String) -> CurrencyGroup? {
        currencyGroups?.first { $0.currency == currency }
    }
}
