import SwiftUI
import UniformTypeIdentifiers

// The macOS settings window, organized per the 2026-11 prototype groups:
// 语言与外观 / 数据与恢复 / 关于. The prototype's "Agent 与自动化" group
// is a browser-only surface (window.paybackAgent) and is intentionally not
// ported (declared in design/DESIGN.md). Cross-device sync keeps its real
// engine-driven configuration flow (docs/sync-design.md).

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var machineNameDraft = ""
    @State private var machineNameLoaded = false
    @State private var confirmingDisable = false
    @State private var detectedFolder: URL?
    @State private var showingPicker = false
    @State private var showingTrash = false
    @State private var showingBackupPicker = false

    var body: some View {
        Form {
            languageSection
            dataSection
            aboutSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 560, minHeight: 520)
        .confirmationDialog(L10n.t(.syncDisableConfirmTitle),
                            isPresented: $confirmingDisable,
                            titleVisibility: .visible) {
            Button(L10n.t(.syncDisable), role: .destructive) {
                model.configureSync(toFolder: nil)
            }
            Button(L10n.t(.cancel), role: .cancel) {}
        } message: {
            Text(L10n.t(.syncDisableConfirmBody))
        }
        .alert(L10n.t(.syncDetectedTitle),
               isPresented: Binding(
                   get: { detectedFolder != nil },
                   set: { if !$0 { detectedFolder = nil } })) {
            Button(L10n.t(.syncUseDetected)) {
                if let folder = detectedFolder {
                    model.configureSync(toFolder: folder)
                }
                detectedFolder = nil
            }
            Button(L10n.t(.syncChooseFolder), role: .cancel) {
                detectedFolder = nil
                showingPicker = true
            }
            Button(L10n.t(.cancel), role: .cancel) {
                detectedFolder = nil
            }
        } message: {
            Text(L10n.t(.syncDetectedBody)
                .replacingOccurrences(of: "{folder}",
                                      with: detectedFolder?.lastPathComponent ?? ""))
        }
        .fileImporter(isPresented: $showingPicker,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let folder = urls.first {
                let scoped = folder.startAccessingSecurityScopedResource()
                model.configureSync(toFolder: folder)
                if scoped { folder.stopAccessingSecurityScopedResource() }
            }
        }
        .fileImporter(isPresented: $showingBackupPicker,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                let scoped = url.startAccessingSecurityScopedResource()
                model.beginRestore(from: url)
                if scoped { url.stopAccessingSecurityScopedResource() }
            }
        }
        .sheet(isPresented: $showingTrash) {
            TrashSheet()
        }
        .sheet(isPresented: $model.showRestoreReview) {
            RestoreReviewSheet()
        }
        .onAppear {
            model.refreshSyncState()
        }
        .onChange(of: model.syncState?.machine.name) { _, newName in
            // load the draft once the first snapshot lands; user edits win
            if !machineNameLoaded, let newName {
                machineNameDraft = newName
                machineNameLoaded = true
            }
        }
    }

    // MARK: 语言与外观

    private var languageSection: some View {
        Section {
            Picker(L10n.t(.languageTitle), selection: languageBinding) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.label).tag(language)
                }
            }
            Text(L10n.t(.languageRowHelp))
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(L10n.t(.appearanceRowLabel), selection: themeBinding) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            Text(L10n.t(.appearanceRowHelp))
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text(L10n.t(.sectionLanguageAppearance))
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { model.uiLanguage }, set: { model.setLanguage($0) })
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { model.theme }, set: { model.setTheme($0) })
    }

    // MARK: 数据与恢复

    private var dataSection: some View {
        Section {
            backupRow
            restoreRow
            trashRow
            syncRow
            if let state = model.syncState, state.enabled {
                folderRow(state)
                machineNameRow(state)
                machinesRow(state)
                if !state.ignoredFiles.isEmpty {
                    Label(
                        L10n.t(.syncIgnoredWarning)
                            .replacingOccurrences(of: "{count}",
                                                  with: String(state.ignoredFiles.count)),
                        systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text(L10n.t(.sectionDataRecovery))
        }
    }

    private var backupRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(.backupExportRow))
                .font(.callout.weight(.medium))
            HStack {
                Text(L10n.t(.backupExportHelp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.t(.backupExportButton)) {
                    model.exportBackup()
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var restoreRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(.restoreRow))
                .font(.callout.weight(.medium))
            HStack {
                Text(L10n.t(.restoreRowHelp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.t(.chooseBackupButton)) {
                    showingBackupPicker = true
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var trashRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(.trashTitle))
                .font(.callout.weight(.medium))
            HStack {
                Text(L10n.t(.trashRowHelp)
                    .replacingOccurrences(of: "{count}",
                                          with: String(model.trashCount)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.t(.trashView)) {
                    model.loadTrash()
                    showingTrash = true
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var syncRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(.syncRowLabel))
                .font(.callout.weight(.medium))
            syncStatusRow
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var syncStatusRow: some View {
        if let state = model.syncState {
            if state.enabled {
                HStack {
                    Label(L10n.t(.syncStatusOn), systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(PaybackTheme.earn)
                    Spacer()
                    Button(L10n.t(.syncDisable), role: .destructive) {
                        confirmingDisable = true
                    }
                    .controlSize(.small)
                }
            } else {
                HStack {
                    Label(L10n.t(.syncStatusOff), systemImage: "tray")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L10n.t(.syncEnable)) {
                        beginEnable()
                    }
                    .controlSize(.small)
                }
            }
        } else {
            HStack { ProgressView().controlSize(.small); Spacer() }
        }
    }

    private func folderRow(_ state: SyncState) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t(.syncFolderLabel))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(state.dir)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            Spacer()
            Button(L10n.t(.syncOpenFolder)) {
                NSWorkspace.shared.open(URL(fileURLWithPath: state.dir))
            }
            .controlSize(.small)
        }
    }

    private func machineNameRow(_ state: SyncState) -> some View {
        HStack {
            Text(L10n.t(.syncMachineNameLabel))
            Spacer()
            TextField(state.machine.name, text: $machineNameDraft)
                .frame(maxWidth: 200)
                .multilineTextAlignment(.trailing)
                .onSubmit { model.renameMachine(machineNameDraft) }
            Button(L10n.t(.save)) {
                model.renameMachine(machineNameDraft)
            }
            .controlSize(.small)
            .disabled(machineNameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func machinesRow(_ state: SyncState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.t(.syncMachinesLabel))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let last = state.lastMergeAt {
                    Text(L10n.t(.syncLastMergeLabel) + ": " + last)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            ForEach(state.machines) { machine in
                HStack(spacing: 8) {
                    Image(systemName: machine.id == state.machine.id
                          ? "laptopcomputer.and.iphone"
                          : "laptopcomputer")
                        .foregroundStyle(.secondary)
                    Text(machine.name)
                    if machine.id == state.machine.id {
                        Text("(\(state.machine.name))")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .font(.callout)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: 关于

    private var aboutSection: some View {
        Section {
            Text(L10n.t(.aboutContent))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("v\(RivetGeneratedConfig.version)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        } header: {
            Text(L10n.t(.aboutMenu))
        }
    }

    // ---------- enable flow ----------

    /// confirm-first: probe the common sync homes; the folder picker is the
    /// fallback when nothing familiar shows up
    private func beginEnable() {
        let candidates = Self.detectSyncFolders()
        if let first = candidates.first {
            detectedFolder = first
        } else {
            showingPicker = true
        }
    }

    static let commonCurrencies = ["CNY", "USD", "EUR", "JPY", "GBP", "HKD",
                                   "TWD", "KRW", "SGD", "AUD", "CAD", "CHF"]

    /// iCloud Drive first (the Apple-ecosystem default), then the cloud
    /// storage mounts File Provider exposes, then classic home folders
    static func detectSyncFolders() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var candidates: [URL] = []
        let icloud = home.appendingPathComponent(
            "Library/Mobile Documents/com~apple~CloudDocs/Payback")
        if FileManager.default.fileExists(atPath: icloud.path) {
            candidates.append(icloud)
        }
        if let cloudStorage = try? FileManager.default.contentsOfDirectory(
            at: home.appendingPathComponent("Library/CloudStorage"),
            includingPropertiesForKeys: nil) {
            for mount in cloudStorage.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let payback = mount.appendingPathComponent("Payback")
                if FileManager.default.fileExists(atPath: payback.path) {
                    candidates.append(payback)
                }
            }
        }
        for name in ["Dropbox", "OneDrive", "Nutstore Files", "坚果云"] {
            let payback = home.appendingPathComponent("\(name)/Payback")
            if FileManager.default.fileExists(atPath: payback.path) {
                candidates.append(payback)
            }
        }
        return candidates
    }
}

// MARK: - trash sheet

/// 最近删除: restorable records, oldest display up to 50 like the
/// prototype; restoring keeps ids and goals intact (no purge exists).
struct TrashSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t(.trashTitle))
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            if let trash = model.trash, !trash.isEmpty {
                Text(L10n.t(.trashIntro))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                List(trash.prefix(50)) { device in
                    HStack(spacing: 12) {
                        DeviceIconTile(category: device.category)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(2)
                            Text(Money.major(device.priceMinor, code: device.currency)
                                 + " · " + formattedDate(device.purchaseDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(L10n.t(.restoreButton)) {
                            model.restoreDevice(id: device.id)
                        }
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                if trash.count > 50 {
                    Text(L10n.t(.trashRowHelp)
                        .replacingOccurrences(of: "{count}",
                                              with: String(trash.count)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
            } else {
                Spacer()
                Text(L10n.t(.trashEmpty))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(width: 480, height: 420)
        .background(PaybackTheme.paper)
    }

    private func formattedDate(_ text: String) -> String {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = Calendar.current.date(from: DateComponents(
                  year: parts[0], month: parts[1], day: parts[2])) else { return text }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = L10n.prefersChinese
            ? Locale(identifier: "zh-CN") : Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - restore review sheet

/// The prototype's 确认恢复备份 flow: validate → review the replace scope →
/// explicit confirm. Validation failures never touch data.
struct RestoreReviewSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.t(.restoreReviewTitle))
                    .font(.headline)
                Spacer()
                Button {
                    model.cancelRestoreReview()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let plan = model.backupPlan {
                HStack(spacing: 16) {
                    StatValue(value: plan.replaceCount,
                              label: L10n.t(.restoreReplacedLabel))
                    StatValue(value: plan.importCount,
                              label: L10n.t(.restoreImportedLabel))
                    StatValue(value: plan.trashCount,
                              label: L10n.t(.restoreTrashLabel))
                }
                Text(L10n.t(.restorePrefsNote))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(L10n.t(.restoreWarning))
                    .font(.caption)
                    .foregroundStyle(PaybackTheme.danger)
            }

            if let error = model.restoreError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(PaybackTheme.danger)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(PaybackTheme.dangerSoft)
                    )
            }

            Spacer(minLength: 0)

            HStack {
                Button(L10n.t(.backupFirst)) {
                    model.exportBackup()
                }
                Spacer()
                Button(L10n.t(.cancel)) {
                    model.cancelRestoreReview()
                }
                .keyboardShortcut(.cancelAction)
                Button(L10n.t(.restoreConfirm)) {
                    model.confirmRestore()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(PaybackTheme.accent)
                .disabled(model.backupPlan == nil)
            }
        }
        .padding(20)
        .frame(width: 480, height: 320)
        .background(PaybackTheme.paper)
    }
}

private struct StatValue: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(PaybackTheme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
