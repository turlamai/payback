import SwiftUI

// Main window: prototype layout (design/prototype/*.html, 2026-11 redesign)
// — sidebar carries brand, investment summary, the device list and the
// settings entry; the workspace is the nonmodal detail pane. Delete is a
// tombstone with an undo toast (docs/data-format.md "Trash").


/// e2e render breadcrumb (issue #64): under PAYBACK_E2E=1 the x64 runner
/// aborts inside Metal during a post-startup render; these probes mark the
/// block that rendered last before the abort.
func paybackRenderProbe(_ tag: String) -> EmptyView {
    if ProcessInfo.processInfo.environment["PAYBACK_E2E"] == "1" {
        FileHandle.standardError.write(Data("payback: render \(tag)\n".utf8))
    }
    return EmptyView()
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings
    @State private var selectedID: Device.ID?
    @State private var confirmingDelete: Device?
    @State private var sortOrder: SortOrder = .added

    enum SortOrder: String, CaseIterable, Identifiable {
        case added
        case date
        case dailyCost

        var id: String { rawValue }

        var label: String {
            switch self {
            case .added: return L10n.t(.sortAdded)
            case .date: return L10n.t(.sortDate)
            case .dailyCost: return L10n.t(.sortDailyCost)
            }
        }

        /// the prototype's contract: added order is the engine's merged
        /// order; 每日成本排序按币种分组，同组数值降序 (DESIGN.md)
        func sort(_ devices: [Device]) -> [Device] {
            switch self {
            case .added:
                return devices
            case .date:
                return devices.sorted { $0.purchaseDate > $1.purchaseDate }
            case .dailyCost:
                return devices.sorted { a, b in
                    if a.currency != b.currency {
                        return a.currency < b.currency
                    }
                    return a.computed.costPerDayMinor > b.computed.costPerDayMinor
                }
            }
        }
    }

    var body: some View {
        paybackRenderProbe("content.body")
        content
            .background(PaybackTheme.paper)
            .preferredColorScheme(model.theme.colorScheme)
            .id(model.uiLanguage)   // rebuild the tree so every string re-resolves
            // a fresh add (and the toast undo): the model publishes the
            // confirmed id once the reload lands it, and the detail pane
            // follows the restored record
            .onChange(of: model.pendingSelection) { _, newValue in
                guard let id = newValue else { return }
                selectedID = id
                model.pendingSelection = nil
            }
            .frame(minWidth: 980, minHeight: 600)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.toggleAppearance()
                } label: {
                    Image(systemName: effectiveDark ? "sun.max" : "moon")
                }
                .help(L10n.t(.toggleAppearance))

                Button {
                    model.beginNewDeviceForm()
                } label: {
                    Label(L10n.t(.addDevice), systemImage: "plus.circle.fill")
                        .foregroundStyle(PaybackTheme.accent)
                }
                .help(L10n.t(.addDevice))
            }
        }
        .confirmationDialog(L10n.t(.deleteConfirmTitle),
                            isPresented: Binding(
                                get: { confirmingDelete != nil },
                                set: { if !$0 { confirmingDelete = nil } }),
                            titleVisibility: .visible,
                            presenting: confirmingDelete) { device in
            Button(L10n.t(.moveToDeleted), role: .destructive) {
                model.deleteDevice(device)
                confirmingDelete = nil
            }
            Button(L10n.t(.keepDevice), role: .cancel) {
                confirmingDelete = nil
            }
        } message: { device in
            Text("\(device.name)\n\(L10n.t(.deleteConfirmText))")
        }
        .sheet(isPresented: $model.showingNewDevice,
               onDismiss: { model.deviceFormDismissed(editing: false) }) {
            DeviceForm(draft: model.rescuedFormDraft() ?? DeviceForm.Draft.new(currency: model.settings.currency),
                       initialPhase: model.rescuedFormPhase(),
                       rescued: model.rescuedFormIsRescue(),
                       onSave: { draft in
                           try await model.addDevice(draft)
                       },
                       onSnapshot: { draft, phase in
                           model.noteDeviceFormSnapshot(draft: draft, phase: phase, editing: nil)
                       })
        }
        // The four secondary presentations live on one anchor view node each:
        // stacked .sheet modifiers on a single SwiftUI view node let any
        // presentation re-evaluation dismiss the active sheet — observed as
        // the add-device form vanishing while the user corrected a field
        // after a failed save on macOS 26 (docs/save-lifecycle.md)
        .background {
            SecondaryPresentations()
        }
        .alert(item: Binding(
            get: { model.errorAlert.map(ErrorText.init) },
            set: { model.errorAlert = $0?.text }
        )) { item in
            Alert(title: Text(L10n.t(.genericError)), message: Text(item.text),
                  dismissButton: .default(Text(L10n.t(.close))))
        }
        .overlay(alignment: .bottom) {
            ToastView()
                .padding(.bottom, 24)
        }
    }

    private var effectiveDark: Bool {
        model.theme == .dark
            || (model.theme == .system
                && NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua)
    }

    @ViewBuilder
    private var content: some View {
        if !model.ready {
            VStack(spacing: 12) {
                ProgressView()
                Text(model.status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.devices.isEmpty {
            NavigationSplitView {
                sidebar
            } detail: {
                EmptyLibraryView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(PaybackTheme.paper)
            }
        } else {
            deviceSplit
        }
    }

    // Apple's answer to "browse a collection, inspect one item" is the
    // nonmodal split: selection-driven detail, no dialog between the user
    // and the next device (HIG: prefer nonmodal design) — and the
    // prototype's own IA: sidebar list + workspace detail.
    private var deviceSplit: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PaybackTheme.paper)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        paybackRenderProbe("sidebar")
        VStack(spacing: 20) {
            brandHeader
            SummaryBlock(summary: model.summary,
                         currency: model.settings.currency,
                         devices: model.devices)
            sortHeader
            List(selection: selectionBinding) {
                ForEach(sortOrder.sort(model.devices)) { device in
                    SidebarDeviceRow(device: device,
                                     selected: device.id == selectedDevice?.id)
                        .tag(device.id)
                        .contextMenu {
                            Button(L10n.t(.edit)) { model.beginEditDeviceForm(device) }
                            Button(L10n.t(.delete), role: .destructive) {
                                confirmingDelete = device
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            sideAddButton
            sidebarFooter
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PaybackTheme.sidebar)
        .navigationSplitViewColumnWidth(min: 280, ideal: 304, max: 400)
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            PaybackTheme.brandmark
            Text("Payback")
                .font(.system(size: 23, weight: .bold))
                .kerning(-0.6)
                .foregroundStyle(PaybackTheme.ink)
            Spacer()
        }
    }

    private var sortHeader: some View {
        HStack {
            Text(L10n.t(.myDevices))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            Spacer()
            Picker(L10n.t(.sortBy), selection: $sortOrder) {
                ForEach(SortOrder.allCases) { order in
                    Text(order.label).tag(order)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .controlSize(.small)
            .tint(PaybackTheme.muted)
        }
        .padding(.bottom, 4)
    }

    private var sideAddButton: some View {
        Button {
            model.beginNewDeviceForm()
        } label: {
            Label(L10n.t(.addDevice), systemImage: "plus")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.bordered)
        .tint(PaybackTheme.accent)
        .padding(.top, 4)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(PaybackTheme.line)
            Button {
                openSettings()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                    Text(L10n.t(.settingsTitle))
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(model.uiLanguage == .en ? "EN" : "中文")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PaybackTheme.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(PaybackTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(PaybackTheme.line, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(PaybackTheme.ink)
        }
    }

    private var selectionBinding: Binding<Device.ID?> {
        Binding(get: { selectedDevice?.id },
                set: { selectedID = $0 })
    }

    // nil id (fresh launch, deleted selection) falls back to the first
    // device so the detail pane is never blank while devices exist
    private var selectedDevice: Device? {
        model.devices.first { $0.id == selectedID } ?? model.devices.first
    }

    @ViewBuilder
    private var detailPane: some View {
        if let device = selectedDevice {
            DeviceDetail(device: device,
                         currency: model.settings.currency,
                         onEdit: { model.beginEditDeviceForm(device) },
                         onDelete: { confirmingDelete = device })
        }
    }
}

/// Anchor node for the secondary presentations (edit device, update,
/// about, celebration): each `.sheet` modifier sits on its own zero-size
/// view so the add-device form's presentation can never be displaced by
/// a competing sheet modifier on the content node.
private struct SecondaryPresentations: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .sheet(item: $model.editingDevice,
                   onDismiss: { model.deviceFormDismissed(editing: true) }) { device in
                DeviceForm(draft: model.rescuedFormDraft() ?? DeviceForm.Draft.from(device),
                           initialPhase: model.rescuedFormPhase(),
                           rescued: model.rescuedFormIsRescue(),
                           onSave: { draft in
                               try await model.updateDevice(draft, id: device.id)
                           },
                           onSnapshot: { draft, phase in
                               model.noteDeviceFormSnapshot(draft: draft, phase: phase,
                                                            editing: device)
                           })
            }
        Color.clear.frame(width: 0, height: 0)
            .sheet(isPresented: $model.showUpdateSheet) {
                UpdateView()
            }
        Color.clear.frame(width: 0, height: 0)
            .sheet(isPresented: $model.showAbout) {
                AboutSheet()
            }
        Color.clear.frame(width: 0, height: 0)
            .sheet(item: $model.celebration) { payload in
                CelebrationView(hits: payload.hits) {
                    model.celebration = nil
                }
            }
    }
}

private struct ErrorText: Identifiable {
    let text: String
    var id: String { text }
}

// ---------- undo toast ----------

/// Bottom-center toast (prototype .toast): message + optional 撤销 action,
/// 10 s when undoable, 6 s otherwise.
struct ToastView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let toast = model.toast {
            HStack(spacing: 16) {
                Text(toast.message)
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.paper)
                if toast.undoID != nil {
                    Button {
                        model.undoDelete()
                    } label: {
                        Text(L10n.t(.undo))
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                Capsule().strokeBorder(PaybackTheme.paper, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(PaybackTheme.paper)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(PaybackTheme.ink)
            )
            .task(id: toast.id) {
                try? await Task.sleep(nanoseconds: toast.undoID == nil
                                        ? 6_000_000_000 : 10_000_000_000)
                if model.toast?.id == toast.id { model.toast = nil }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

// ---------- sidebar summary ----------

/// The prototype's .sidebar-summary: investment hero for the default
/// currency group, static caption, and the two mini stats. All numbers
/// come from the engine's summary; hosts only pick the group and format.
struct SummaryBlock: View {
    let summary: Summary
    let currency: String
    let devices: [Device]

    private var group: CurrencyGroup? {
        summary.currencyGroups?.first { $0.currency == currency }
    }

    private var mixed: Bool {
        devices.contains { $0.currency != currency }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t(.investmentEyebrow)
                .replacingOccurrences(of: "{currency}", with: currency))
                .font(.system(size: 13, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(PaybackTheme.muted)
            Text(investmentText)
                .font(.system(size: 30, weight: .semibold))
                .kerning(-1)
                .monospacedDigit()
                .foregroundStyle(PaybackTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 6)
            Text(L10n.t(.investmentCaption))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 6)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dailyText)
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(PaybackTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(L10n.t(.dailyCostTotal))
                        .font(.system(size: 13))
                        .foregroundStyle(PaybackTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(summary.deviceCount)")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(PaybackTheme.ink)
                    Text(L10n.t(.devicesTracked))
                        .font(.system(size: 13))
                        .foregroundStyle(PaybackTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 20)

            if mixed {
                Text(L10n.t(.mixedCurrencyNote))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
                    .padding(.top, 12)
            }
        }
    }

    // Mixed portfolios never show one combined money value: only the
    // default currency's group is summarized, per the prototype (#23).
    private var investmentText: String {
        if let spent = group?.totalSpentMinor {
            return Money.major(spent, code: currency)
        }
        return Money.major(Int64(0), code: currency)
    }

    private var dailyText: String {
        if let sum = group?.dailyCostSumMinor {
            return Money.perDay(sum, code: currency)
        }
        return Money.perDay(Double(0), code: currency)
    }
}

// ---------- device sidebar row ----------

/// Prototype .device-row: linear category icon in a bordered tile, name
/// and cost/day sub line, goal-met dot on the trailing edge.
struct SidebarDeviceRow: View {
    let device: Device
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            DeviceIconTile(category: device.category, selected: selected)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(PaybackTheme.ink)
                Text(subLine)
                    .font(.system(size: 13))
                    .foregroundStyle(PaybackTheme.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            if device.computed.paidBack {
                Circle()
                    .fill(PaybackTheme.earn)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? PaybackTheme.surface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? PaybackTheme.line : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private var subLine: String {
        let cost = Money.perDay(device.computed.costPerDayMinor, code: device.currency)
        return device.computed.paidBack
            ? cost + L10n.t(.perDay) + " · " + L10n.t(.paidBack)
            : cost + L10n.t(.perDay)
    }
}

/// 40×40 bordered tile with the linear category symbol; selected rows tint
/// it soft/accent like the prototype's .device-icon.
struct DeviceIconTile: View {
    let category: String
    var selected: Bool = false
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: CategoryIcon.symbol(for: category))
            .font(.system(size: size * 0.45, weight: .regular))
            .foregroundStyle(selected ? PaybackTheme.accent : PaybackTheme.muted)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? PaybackTheme.soft : PaybackTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Color.clear : PaybackTheme.line,
                                  lineWidth: 1)
            )
    }
}

// ---------- empty library ----------

/// The prototype's empty screen (design/prototype/empty.html): box symbol,
/// title, hint, primary add action, and the worked example line.
struct EmptyLibraryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PaybackTheme.soft)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "shippingbox")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(PaybackTheme.accent)
                )
            Text(L10n.t(.emptyTitle))
                .font(.system(size: 28, weight: .semibold))
                .kerning(-0.7)
                .foregroundStyle(PaybackTheme.ink)
            Text(L10n.t(.emptyHint))
                .font(.system(size: 15))
                .foregroundStyle(PaybackTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            Button {
                model.beginNewDeviceForm()
            } label: {
                Label(L10n.t(.addFirstDevice), systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(PaybackTheme.accent)
            Text(L10n.t(.emptyExample))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
