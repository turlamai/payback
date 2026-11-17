import SwiftUI
import RivetEmbedding
import RivetRuntime
import RivetSystem
import UserNotifications

@main
struct RivetHostApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Payback") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 680, minHeight: 480)
                .task { model.start() }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L10n.t(.aboutMenu)) { model.showAbout = true }
            }
            // Family menu convention: Check for Updates… lives in the App
            // menu directly below About.
            CommandGroup(after: .appInfo) {
                Button(L10n.t(.checkUpdatesMenu)) { model.checkForUpdates() }
                    .keyboardShortcut("u", modifiers: .command)
            }
        }
        // SwiftUI.Settings spelled out: our wire model type is also named
        // Settings and would shadow the scene otherwise
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 480)
                .frame(minHeight: 420)
        }
    }
}

/// UI language preference. Since the 2026-11 redesign this lives in the
/// engine's per-machine settings (docs/data-format.md) so it rides the
/// backup format; the pre-redesign UserDefaults key migrates on first load.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zh
    case en

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return L10n.t(.languageAuto)
        case .zh: return "中文"
        case .en: return "English"
        }
    }

    /// engine settings value ("system" | "zh-CN" | "en")
    var settingsValue: String {
        switch self {
        case .system: return "system"
        case .zh: return "zh-CN"
        case .en: return "en"
        }
    }

    static func from(settingsValue: String?) -> AppLanguage {
        switch settingsValue {
        case "zh-CN": return .zh
        case "en": return .en
        default: return .system
        }
    }
}

/// Appearance preference (2026-11 redesign): system/light/dark, engine
/// settings-backed so it rides the backup too.
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return L10n.t(.appearanceSystem)
        case .light: return L10n.t(.appearanceLight)
        case .dark: return L10n.t(.appearanceDark)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    static func from(settingsValue: String?) -> AppTheme {
        AppTheme(rawValue: settingsValue ?? "") ?? .system
    }
}

@MainActor
extension DeviceForm.SavePhase {
    var isFailed: Bool { if case .failed = self { true } else { false } }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var ready = false
    @Published var status = L10n.t(.startingBackend)
    @Published var devices: [Device] = []
    @Published var settings = Settings()
    @Published var summary = Summary.empty
    @Published var appInfo = AppInfo(version: "0.0.0", build: 0, identifier: "", channel: "stable")
    @Published var updateState: UpdateState = .idle
    @Published var showUpdateSheet = false
    /// metadata of the newest available update (version, size); shown in the sheet
    @Published var updateInfo: UpdateCheckResult?
    @Published var errorAlert: String?
    @Published var celebration: CelebrationPayload?

struct CelebrationPayload: Identifiable {
    let id = UUID()
    let hits: [MilestoneHit]
}
    // ---------- trash / undo (2026-11 redesign) ----------
    /// tombstoned records reported by load-all; drives the settings row
    @Published var trashCount = 0
    /// full trash records, loaded on demand for the restore sheet
    @Published var trash: [Device]?
    /// the toast line + the undoable deletion behind it
    @Published var toast: ToastState?

    struct ToastState: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let undoID: String?
    }

    /// appearance preference, engine settings-backed (2026-11 redesign)
    @Published var theme: AppTheme = .system

    @Published var editingDevice: Device?   // presents DeviceForm for an existing row
    @Published var showingNewDevice = false // presents DeviceForm for a new draft
    /// device id the list should select after the next reload (a fresh add)
    @Published var pendingSelection: Device.ID?
    @Published var showAbout = false        // presents AboutSheet

    // Issue #30: current macOS hosts dismiss the sheet when a keystroke
    // on a FAILED form would make it valid — and the breadcrumbs from the
    // CI runs settle the route: the dismissal goes through the CANCEL
    // action (the button closure runs, flipping the phase to idle before
    // the dismissed callback fires, ahead of the edited value landing in
    // the field). interactiveDismissDisabled does not block it, and the
    // phase is idle by the time anyone can look — so "was the phase
    // failed" cannot tell a platform kill from the user's own Esc. The
    // discriminator that survives is the edit itself: a DRAFT CHANGE
    // while the phase is failed arms the rescue; a failed form the user
    // merely Escapes from (no edit) stays disarmed and closes per the
    // contract. The re-assertion presents a FRESH idle form carrying the
    // typed draft — idle forms edit stably on these hosts, which breaks
    // the trigger while keeping the input; the next failed save re-renders
    // the banner from scratch. Bounded per failed-phase stretch.
    struct DeviceFormRescue {
        var draft: DeviceForm.Draft?
        var phase: DeviceForm.SavePhase = .idle
        var editingRef: Device?
        var editedWhileFailed = false
        var attempts = 0
    }
    private var formRescue = DeviceFormRescue()

    /// fresh form: the rescue mirror starts clean
    func beginNewDeviceForm() {
        formRescue = DeviceFormRescue()
        showingNewDevice = true
    }

    /// edit form: remember which row is being edited so a forced dismissal
    /// can re-present it (the item binding nils out on any dismissal)
    func beginEditDeviceForm(_ device: Device) {
        formRescue = DeviceFormRescue()
        formRescue.editingRef = device
        editingDevice = device
    }

    /// called by the form after every (draft, phase) change
    func noteDeviceFormSnapshot(draft: DeviceForm.Draft,
                                phase: DeviceForm.SavePhase,
                                editing: Device?) {
        var changed = false
        if let previous = formRescue.draft, previous != draft { changed = true }
        if phase.isFailed, changed {
            formRescue.editedWhileFailed = true
            rescueLog("armed: draft changed while failed (\(formRescue.draft?.priceText ?? "?") -> \(draft.priceText))")
        }
        if rescueVerbose, changed, !phase.isFailed {
            rescueLog("idle draft change: name=\(draft.name) price=\(draft.priceText)")
        }
        formRescue.draft = draft
        formRescue.phase = phase
        if let editing { formRescue.editingRef = editing }
        if phase == .idle { formRescue.attempts = 0 }
    }

    /// presentation seed: the rescued state after a forced dismissal, else fresh
    func rescuedFormDraft() -> DeviceForm.Draft? { formRescue.draft }
    func rescuedFormPhase() -> DeviceForm.SavePhase { formRescue.phase }
    /// true when the upcoming presentation is a rescue re-assert
    func rescuedFormIsRescue() -> Bool { formRescue.attempts > 0 }

    /// stderr breadcrumbs for the rescue path: the e2e suite captures the
    /// app's stderr and #30's trigger cannot be seen from the AX tree
    /// alone. Verbose per-keystroke snapshots only under PAYBACK_E2E=1
    /// (set by the e2e launcher); dismissal/re-assert always log.
    private var rescueVerbose: Bool {
        ProcessInfo.processInfo.environment["PAYBACK_E2E"] == "1"
    }
    private func rescueLog(_ line: String) {
        FileHandle.standardError.write(Data("payback: rescue: \(line)\n".utf8))
    }

    /// the re-presented SwiftUI sheet's NSWindow appears a beat after the
    /// presentation flag flips. A sheet keys over its parent, so keep the
    /// MAIN window key while waiting, then key the sheet the moment it
    /// exists and log whether the keying actually took (makeKey can be
    /// silently refused on a modal child). Bounded at 2 s.
    private func keySheetWindowWhenItAppears() {
        var tries = 0
        func tick() {
            tries += 1
            if let sheetWindow = NSApp.windows.first(where: { $0.sheetParent != nil }) {
                sheetWindow.makeKey()
                NSApp.activate(ignoringOtherApps: true)
                rescueLog("keyed sheet (try \(tries)) isKey=\(sheetWindow.isKeyWindow)")
            } else if tries < 40 {
                if let main = NSApp.mainWindow { main.makeKey() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: tick)
            } else {
                rescueLog("no sheet window found to key")
            }
        }
        tick()
    }

    /// the sheet went away: re-present it when the mirror says the user
    /// was editing a failed form (or the phase is still failed outright);
    /// an unedited Esc closes per the contract
    func deviceFormDismissed(editing: Bool) {
        var forced = false
        if case .failed = formRescue.phase { forced = true }
        forced = forced || formRescue.editedWhileFailed
        rescueLog("dismissed editing=\(editing) phase=\(formRescue.phase) forced=\(forced) attempts=\(formRescue.attempts)")
        guard forced, formRescue.draft != nil, formRescue.attempts < 3 else {
            formRescue = DeviceFormRescue()
            rescueLog("dismissed: no re-assert")
            return
        }
        formRescue.attempts += 1
        // one rescue per armed stretch: the re-presented idle form starts
        // with a clean trigger (a later failed save re-arms it on edit)
        formRescue.editedWhileFailed = false
        // the banner does not survive the re-presentation (see above): the
        // seed phase drops to idle so the form comes back editable and
        // stable; the draft carries the user's typed values
        formRescue.phase = .idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // well outside the dismissal transaction: re-presenting too
            // early lands inside the teardown's tail and the new sheet
            // comes up broken. A programmatic re-present does not
            // reliably key the sheet on these hosts — and keystrokes
            // route to the key window only — so poll for the sheet's
            // NSWindow and make it key the moment it exists.
            NSApp.activate(ignoringOtherApps: true)
            self.rescueLog("re-assert #\(self.formRescue.attempts)")
            if editing, let ref = self.formRescue.editingRef {
                self.editingDevice = ref
            } else {
                self.showingNewDevice = true
            }
            self.keySheetWindowWhenItAppears()
        }
    }

    @Published var syncState: SyncState?    // snapshot for the settings pane
    private var syncRevisionSeen: Int64 = -1
    private var syncPollTimer: Timer?

    /// changing this rebuilds the whole view tree, so strings re-resolve.
    /// The engine settings are the source of truth (backup contract);
    /// setLanguage writes there and the reload echoes it back.
    @Published var uiLanguage: AppLanguage {
        didSet {
            L10n.override = uiLanguage == .system ? nil : uiLanguage.rawValue
        }
    }

    /// guards the reload echo: the engine confirm re-enters via reload()
    private var languageWriteInFlight = false
    private var themeWriteInFlight = false
    /// the pre-redesign UserDefaults key migrates into engine settings once
    private let legacyLanguageKey = "payback.uiLanguage"

    init() {
        // start from the legacy key until the first load-all lands; the
        // migration below then carries it into engine settings exactly once
        let stored = UserDefaults.standard.string(forKey: "payback.uiLanguage")
            ?? AppLanguage.system.rawValue
        let language = AppLanguage(rawValue: stored) ?? .system
        self.uiLanguage = language
        L10n.override = language == .system ? nil : language.rawValue
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != uiLanguage else { return }
        uiLanguage = language
        languageWriteInFlight = true
        saveSetting(["language": language.settingsValue])
    }

    func setTheme(_ theme: AppTheme) {
        guard theme != self.theme else { return }
        self.theme = theme
        themeWriteInFlight = true
        saveSetting(["theme": theme.rawValue])
    }

    /// quick toggle for the toolbar: flips light/dark around the current
    /// effective appearance
    func toggleAppearance() {
        let effectiveDark = theme == .dark
            || (theme == .system && NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua)
        setTheme(effectiveDark ? .light : .dark)
    }

    private func saveSetting(_ patch: [String: String]) {
        guard let api else { return }
        Task {
            do {
                let payload = try JSONEncoder().encode(patch)
                let data = try await api.save_settings(payload: payload)
                let settings = try JSONDecoder().decode(Settings.self, from: data)
                self.settings = settings
                applyEnginePreferences(settings)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    /// engine settings are the display-preference source of truth; the
    /// in-flight guards keep a user choice from being overwritten by the
    /// echo of its own save
    private func applyEnginePreferences(_ settings: Settings) {
        if !themeWriteInFlight {
            let engineTheme = AppTheme.from(settingsValue: settings.theme)
            if engineTheme != theme { theme = engineTheme }
        }
        if !languageWriteInFlight {
            let engineLanguage = AppLanguage.from(settingsValue: settings.language)
            if engineLanguage != uiLanguage { uiLanguage = engineLanguage }
        }
        themeWriteInFlight = false
        languageWriteInFlight = false
    }

    private var backend: EmbeddedRacketBackend?
    private var pollTimer: Timer?

    var api: RivetAPI? {
        guard let backend else { return nil }
        return RivetAPI(client: backend.client)
    }

    /// Synchronous backend start on the main actor (taskly family pattern):
    /// spawning + handshake is fast, and keeping it here avoids capturing
    /// non-Sendable state across a detached task — older Swift 6 toolchains
    /// (macOS Intel runners) reject that pattern outright.
    func start() {
        guard backend == nil else { return }
        UpdaterInstaller.cleanupStaleBackup()
        do {
            let config = try Self.runtimeConfiguration()
            let backend = EmbeddedRacketBackend(configuration: config)
            self.backend = backend
            do {
                try backend.start()
                FileHandle.standardError.write(
                    Data("payback: backend started\n".utf8))
                ready = true
                status = ""
                reload()
                autoCheckForUpdates()
                runDailyDigest()
                startSyncPolling()
            } catch {
                FileHandle.standardError.write(
                    Data("payback: backend failed: \(error)\n".utf8))
                status = L10n.t(.backendError) + ": \(error)"
            }
        } catch {
            FileHandle.standardError.write(
                Data("payback: config failed: \(error)\n".utf8))
            status = L10n.t(.configError) + ": \(error)"
        }
    }

    // ---------- emotional layer ----------

    /// celebrate milestones achieved since the last launch
    private func detectCelebrations(in devices: [Device]) {
        var hits: [MilestoneHit] = []
        for device in devices {
            for milestone in device.computed.milestones
            where milestone.new == true && milestone.achieved {
                hits.append(MilestoneHit(deviceName: device.name,
                                         icon: device.icon,
                                         key: milestone.key))
            }
        }
        if !hits.isEmpty {
            // let the list land first; celebrate right after
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                self.celebration = CelebrationPayload(hits: hits)
            }
        }
    }

    /// once-per-day system notification: the payback digest. Permission
    /// denial is remembered and never re-prompted; every failure is silent.
    private func runDailyDigest() {
        guard let api else { return }
        Task {
            do {
                let data = try await api.daily_digest()
                let digest = try JSONDecoder().decode(DigestResult.self, from: data)
                guard digest.status == "ok",
                      !UserDefaults.standard.bool(forKey: "payback.digest.denied") else { return }
                // a bare staged binary has no bundle id — UNUserNotificationCenter
                // raises NSException there (Swift cannot catch it); only ask
                // inside a real bundle
                guard Bundle.main.bundleIdentifier != nil else { return }
                let granted = (try? await RivetNotifications.requestAuthorization()) ?? false
                guard granted else {
                    UserDefaults.standard.set(true, forKey: "payback.digest.denied")
                    return
                }
                // mixed portfolios join per-currency totals; the combined
                // scalar is null then (#23)
                let earnedText: String
                if let total = digest.earnedTotalMinor {
                    earnedText = Money.major(total, code: settings.currency)
                } else if let per = digest.earnedPerCurrency, !per.isEmpty {
                    earnedText = per
                        .map { amount -> String in
                            Money.major(amount.earnedTotalMinor,
                                        code: amount.currency)
                        }
                        .joined(separator: " · ")
                } else {
                    earnedText = Money.major(0.0, code: settings.currency)
                }
                var body = L10n.t(.digestBody)
                    .replacingOccurrences(of: "{earned}", with: earnedText)
                if let name = digest.bestDeviceName {
                    let cost = Money.perDay(digest.bestDeviceCostPerDayMinor ?? 0,
                                            code: digest.bestDeviceCurrency
                                                ?? settings.currency)
                    body += "\n" + L10n.t(.digestBodyBest)
                        .replacingOccurrences(of: "{name}", with: name)
                        .replacingOccurrences(of: "{cost}", with: cost)
                }
                try? await RivetNotifications.show(title: L10n.t(.digestTitle),
                                                   body: body)
            } catch {
                // silent: the digest is a delight, never an interruption
                FileHandle.standardError.write(
                    Data("payback: digest error: \(error)\n".utf8))
            }
        }
    }

    // ---------- data ----------

    func reload() {
        guard let api, ready else { return }
        Task {
            do {
                let data = try await api.load_all()
                let document = try JSONDecoder().decode(LoadAllDocument.self, from: data)
                devices = document.devices
                settings = document.settings
                summary = document.summary
                appInfo = document.app
                trashCount = document.trashCount ?? trashCount
                detectCelebrations(in: document.devices)
                migrateLegacyLanguage(settings: document.settings)
                applyEnginePreferences(document.settings)
            } catch {
                errorAlert = "\(error)"
            }
        }
    }

    /// the pre-redesign language choice moves into engine settings once, on
    /// the first load where the engine still says "system"
    private func migrateLegacyLanguage(settings: Settings) {
        guard settings.language == nil || settings.language == "system",
              let legacy = UserDefaults.standard.string(forKey: legacyLanguageKey),
              let language = AppLanguage(rawValue: legacy), language != .system
        else {
            UserDefaults.standard.removeObject(forKey: legacyLanguageKey)
            return
        }
        UserDefaults.standard.removeObject(forKey: legacyLanguageKey)
        guard let api else { return }
        Task {
            let payload = try? JSONEncoder().encode(["language": language.settingsValue])
            guard let payload else { return }
            _ = try? await api.save_settings(payload: payload)
        }
    }

    /// Persists a new device and returns its id. Failures throw to the
    /// form, which owns the retry — never to the window-level alert (#24).
    @discardableResult
    func addDevice(_ draft: DeviceDraft) async throws -> String {
        guard let api else { throw BackendUnavailable() }
        let payload = try JSONEncoder().encode(draft)
        let created = try await api.add_device(payload: payload)
        showingNewDevice = false
        reload()
        // the detail pane follows the record the user just wrote
        if let id = try? Self.deviceId(from: created) {
            pendingSelection = id
        }
        return (try? Self.deviceId(from: created)) ?? ""
    }

    /// Full replace of an existing device; the id travels in the payload.
    @discardableResult
    func updateDevice(_ draft: DeviceDraft, id: String) async throws -> String {
        guard let api else { throw BackendUnavailable() }
        var payload = try JSONEncoder().encode(draft)
        if var object = try JSONSerialization.jsonObject(with: payload) as? [String: Any] {
            object["id"] = id
            payload = try JSONSerialization.data(withJSONObject: object)
        }
        _ = try await api.update_device(payload: payload)
        editingDevice = nil
        reload()
        return id
    }

    private static func deviceId(from payload: Data) throws -> String {
        guard let object = try JSONSerialization.jsonObject(with: payload) as? [String: Any],
              let id = object["id"] as? String else {
            throw BackendUnavailable()
        }
        return id
    }

    func deleteDevice(_ device: Device) {
        guard let api else { return }
        Task {
            do {
                _ = try await api.delete_device(id: device.id)
                reload()
                showToast(L10n.t(.toastDeleted), undoID: device.id)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    // ---------- trash / undo (docs/data-format.md "Trash") ----------

    /// the toast's 撤销: reinstate the tombstoned record via restore-device
    func undoDelete() {
        guard let id = toast?.undoID else { return }
        toast = nil
        restoreDevice(id: id, followSelection: true)
    }

    /// restore from the trash sheet; selection follows only for the toast
    /// undo (the prototype's 撤销 opens the restored record)
    func restoreDevice(id: String, followSelection: Bool = false) {
        guard let api else { return }
        Task {
            do {
                _ = try await api.restore_device(id: id)
                if followSelection { pendingSelection = id }
                reload()
                showToast(L10n.t(.deviceRestored), undoID: nil)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    func loadTrash() {
        guard let api else { return }
        Task {
            do {
                let data = try await api.trash_list()
                trash = try JSONDecoder().decode(TrashDocument.self, from: data).trash
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    func showToast(_ message: String, undoID: String?) {
        toast = ToastState(message: message, undoID: undoID)
    }

    // ---------- backup (docs/data-format.md "payback.backup") ----------

    @Published var backupPlan: BackupValidateResult?
    @Published var pendingBackupData: Data?
    @Published var showRestoreReview = false
    @Published var restoreError: String?

    /// export: the engine serializes the full document; the host only
    /// writes it where the user asks
    func exportBackup() {
        guard let api else { return }
        Task {
            do {
                let data = try await api.backup_export()
                let panel = NSSavePanel()
                panel.nameFieldStringValue = "payback-backup-\(Self.todayStamp()).json"
                panel.allowedContentTypes = [.json]
                guard panel.runModal() == .OK, let url = panel.url else { return }
                try data.write(to: url)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    /// validate first (no writes); on success the review sheet presents the
    /// replace scope for explicit confirmation
    func beginRestore(from url: URL) {
        guard let api else { return }
        Task {
            do {
                let data = try Data(contentsOf: url)
                guard data.count <= 5_000_000 else {
                    restoreError = L10n.t(.backupTooLarge)
                    return
                }
                let result = try await api.backup_validate(payload: data)
                pendingBackupData = data
                backupPlan = try JSONDecoder().decode(BackupValidateResult.self,
                                                      from: result)
                restoreError = nil
                showRestoreReview = true
            } catch {
                // engine messages are user-visible; the generic invalid
                // copy leads, the specific reason follows
                restoreError = L10n.t(.backupInvalid) + "\n" + Self.cleanError(error)
            }
        }
    }

    func confirmRestore() {
        guard let api, let data = pendingBackupData else { return }
        Task {
            do {
                _ = try await api.backup_restore(payload: data)
                pendingBackupData = nil
                backupPlan = nil
                showRestoreReview = false
                reload()
                showToast(L10n.t(.backupRestored), undoID: nil)
            } catch {
                restoreError = Self.cleanError(error)
            }
        }
    }

    func cancelRestoreReview() {
        pendingBackupData = nil
        backupPlan = nil
        showRestoreReview = false
        restoreError = nil
    }

    static func todayStamp() -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d",
                      parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // ---------- sync (docs/sync-design.md) ----------

    /// Poll the engine: external shard changes bump the revision, and the
    /// poll answers with a load-all so the whole UI re-renders from the
    /// merged view. Also keeps the settings pane's snapshot warm.
    func startSyncPolling() {
        syncPollTimer?.invalidate()
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollSyncState() }
        }
        RunLoop.main.add(timer, forMode: .common)
        syncPollTimer = timer
        pollSyncState()
    }

    func refreshSyncState() {
        pollSyncState()
    }

    private func pollSyncState() {
        guard let api, ready else { return }
        Task {
            do {
                let data = try await api.sync_state()
                let state = try JSONDecoder().decode(SyncState.self, from: data)
                syncState = state
                if state.revision != syncRevisionSeen {
                    let first = syncRevisionSeen == -1
                    syncRevisionSeen = state.revision
                    // the first snapshot primes the pane; later bumps mean
                    // another machine (or this one via another window)
                    // changed the merged view
                    if !first { reload() }
                }
            } catch {
                // silent: the poll is an optimization, never an alarm
            }
        }
    }

    /// dir nil = turn sync off and bring the claims back to the local
    /// directory; a URL = point the engine at that folder
    func configureSync(toFolder folder: URL?) {
        guard let api else { return }
        Task {
            do {
                let dirValue: Any = folder.map { $0.path } ?? NSNull()
                let payload = try JSONSerialization.data(
                    withJSONObject: ["dir": dirValue])
                let data = try await api.configure_sync(payload: payload)
                syncState = try JSONDecoder().decode(SyncState.self, from: data)
                syncRevisionSeen = syncState?.revision ?? syncRevisionSeen
                reload()
            } catch {
                errorAlert = L10n.t(.syncEnableFailed) + ": " + Self.cleanError(error)
            }
        }
    }

    func renameMachine(_ name: String) {
        guard let api else { return }
        Task {
            do {
                let payload = try JSONEncoder().encode(
                    ["name": name.trimmingCharacters(in: .whitespacesAndNewlines)])
                let data = try await api.rename_machine(payload: payload)
                syncState = try JSONDecoder().decode(SyncState.self, from: data)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    /// currency rides the sync whitelist: saving it claims a settings
    /// entry, so one machine's choice becomes every machine's default
    func saveCurrency(_ code: String) {
        guard let api, code != settings.currency else { return }
        Task {
            do {
                let payload = try JSONEncoder().encode(["currency": code])
                let data = try await api.save_settings(payload: payload)
                settings = try JSONDecoder().decode(Settings.self, from: data)
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    // ---------- updates ----------

    private func autoCheckForUpdates() {
        guard settings.updateAutoCheck else { return }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            // silent on failure: a launch-time check never nags
            checkUpdates(throttled: true, present: false)
        }
    }

    func checkForUpdates() {
        checkUpdates(throttled: false, present: true)
    }

    private func checkUpdates(throttled: Bool, present: Bool) {
        guard let api else { return }
        Task {
            do {
                let data = try await api.check_updates(force: !throttled)
                let result = try JSONDecoder().decode(UpdateCheckResult.self, from: data)
                if result.status == "available" && present {
                    updateInfo = result
                    // an explicit available phase: the sheet offers the
                    // download (consent first, matching the Windows flow) —
                    // idle here rendered as "up to date" and nothing ever
                    // started the download
                    updateState = UpdateState(phase: "available", percent: 0,
                                              message: nil, downloadedPath: nil,
                                              availableVersion: result.availableVersion)
                    showUpdateSheet = true
                } else if result.status == "up-to-date" && present {
                    updateState = .upToDate
                    showUpdateSheet = true
                } else if result.status == "error" && present {
                    updateState = .error(result.message ?? "unknown error")
                    showUpdateSheet = true
                }
            } catch {
                if present {
                    updateState = .error("\(error)")
                    showUpdateSheet = true
                }
            }
        }
    }

    func startDownload() {
        guard let api else { return }
        Task {
            do {
                _ = try await api.start_download()
                startPolling()
            } catch {
                errorAlert = Self.cleanError(error)
            }
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollUpdateState() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        pollUpdateState()
    }

    private func pollUpdateState() {
        guard let api else { return }
        Task {
            do {
                let data = try await api.update_state()
                let state = try JSONDecoder().decode(UpdateState.self, from: data)
                updateState = state
                if state.phase != "downloading" {
                    pollTimer?.invalidate()
                    pollTimer = nil
                }
            } catch {
                pollTimer?.invalidate()
                pollTimer = nil
            }
        }
    }

    func installUpdate() {
        guard updateState.phase == "downloaded",
              let path = updateState.downloadedPath else { return }
        do {
            try UpdaterInstaller.install(dmgAt: URL(fileURLWithPath: path))
        } catch {
            errorAlert = L10n.t(.installFailed) + ": \(error)"
        }
    }

    // ---------- helpers ----------

    static func cleanError(_ error: Error) -> String {
        let text = "\(error)"
        // RVT1 failures arrive as "...error: <message>"; keep the message
        if let range = text.range(of: "error: ") {
            return String(text[range.upperBound...])
        }
        return text
    }

    private static func runtimeConfiguration() throws -> EmbeddedRacketConfiguration {
        let executable = Bundle.main.executableURL
            ?? URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL

        // Packaged apps keep Racket data in Contents/Resources. `raco rivet
        // dev` runs the staged executable directly, where runtime/res live
        // next to the executable. Pick the first complete layout so both
        // paths use exactly the same host binary.
        let roots = [
            Bundle.main.resourceURL,
            executable.deletingLastPathComponent()
        ].compactMap { $0 }

        for root in roots {
            let runtime = root.appendingPathComponent("runtime", isDirectory: true)
            let core = root.appendingPathComponent("res/core.zo")
            let required = [
                runtime.appendingPathComponent("petite.boot"),
                runtime.appendingPathComponent("scheme.boot"),
                runtime.appendingPathComponent("racket.boot"),
                core
            ]
            if required.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }) {
                // The embedded runtime resolves its foreign libraries
                // (libgmp and friends) relative to the working directory;
                // packaged apps must therefore run from their Resources
                // directory so "runtime/lib/..." lands inside the bundle
                // (scripts/post-package.sh copies the libraries there).
                FileManager.default.changeCurrentDirectoryPath(root.path)
                return EmbeddedRacketConfiguration(
                    executable: executable,
                    petiteBoot: required[0],
                    schemeBoot: required[1],
                    racketBoot: required[2],
                    core: core,
                    moduleName: RivetGeneratedConfig.moduleName,
                    entryName: RivetGeneratedConfig.entryName
                )
            }
        }

        throw HostError.missingRuntimeLayout(
            roots.map(\.path).joined(separator: ", ")
        )
    }
}

/// The backend pipe is not up yet; the device form reports this like any
/// other save failure instead of silently dropping the save (#24).
struct BackendUnavailable: LocalizedError {
    var errorDescription: String? { L10n.t(.startingBackend) }
}

enum HostError: Error, CustomStringConvertible {
    case missingRuntimeLayout(String)

    var description: String {
        switch self {
        case .missingRuntimeLayout(let roots):
            return "missing Rivet runtime/res layout under: \(roots)"
        }
    }
}
