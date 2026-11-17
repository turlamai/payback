import SwiftUI

// Library tab: the prototype's sidebar-summary + device list, then the
// detail. Compact width stacks with a back button (the <768px contract);
// regular width (iPad) uses the nonmodal split, matching the desktop.

struct LibraryView: View {
    @EnvironmentObject private var session: CompanionSession
    @State private var selectedID: Device.ID?
    @State private var confirmingDelete: Device?
    @State private var showingTrash = false

    private var devices: [Device] { session.document?.devices ?? [] }
    private var summary: Summary? { session.document?.summary }
    private var currency: String { session.document?.settings.currency ?? "CNY" }

    var body: some View {
        NavigationStack {
            content
                .background(PaybackTheme.paper)
                .navigationTitle("Payback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await session.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(session.clientInactive)
                    }
                }
                .refreshable {
                    await session.refresh()
                }
        }
        .confirmationDialog(L10n.t(.deleteConfirmTitle),
                            isPresented: Binding(
                                get: { confirmingDelete != nil },
                                set: { if !$0 { confirmingDelete = nil } }),
                            titleVisibility: .visible,
                            presenting: confirmingDelete) { device in
            Button(L10n.t(.moveToDeleted), role: .destructive) {
                Task { await session.delete(device) }
            }
            Button(L10n.t(.keepDevice), role: .cancel) {}
        } message: { device in
            Text("\(device.name)\n\(L10n.t(.deleteConfirmText))")
        }
        .sheet(isPresented: $showingTrash) {
            TrashSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        if devices.isEmpty {
            emptyState
        } else {
            listContent
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PaybackTheme.soft)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "shippingbox")
                        .font(.system(size: 36))
                        .foregroundStyle(PaybackTheme.accent)
                )
            Text(L10n.t(.emptyTitle))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            Text(L10n.t(.emptyHint))
                .font(.system(size: 15))
                .foregroundStyle(PaybackTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if session.clientInactive {
                Text(L10n.t(.companionIdle))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var listContent: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                sidebar
            } detail: {
                detailPane
                    .background(PaybackTheme.paper)
            }
        } else {
            List {
                Section {
                    SummaryHeaderBlock(summary: summary, currency: currency,
                                       devices: devices)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                Section(L10n.t(.myDevices)) {
                    ForEach(devices) { device in
                        NavigationLink {
                            DeviceDetailPage(device: device,
                                             currency: currency,
                                             onDelete: { confirmingDelete = device })
                        } label: {
                            DeviceRow(device: device)
                        }
                    }
                }
                Section {
                    Button {
                        Task {
                            await session.loadTrash()
                            showingTrash = true
                        }
                    } label: {
                        Label(L10n.t(.trashTitle)
                            + " (\(session.document?.trashCount ?? 0))",
                              systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(PaybackTheme.paper)
        }
    }

    private var sidebar: some View {
        List(selection: $selectedID) {
            Section {
                SummaryHeaderBlock(summary: summary, currency: currency,
                                   devices: devices)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            Section(L10n.t(.myDevices)) {
                ForEach(devices) { device in
                    NavigationLink(value: device.id) {
                        DeviceRow(device: device)
                    }
                    .tag(device.id)
                }
            }
            Section {
                Button {
                    Task {
                        await session.loadTrash()
                        showingTrash = true
                    }
                } label: {
                    Label(L10n.t(.trashTitle)
                        + " (\(session.document?.trashCount ?? 0))",
                          systemImage: "trash")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PaybackTheme.sidebar)
        .navigationSplitViewColumnWidth(min: 280, ideal: 304, max: 380)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let device = devices.first(where: { $0.id == selectedID }) ?? devices.first {
            DeviceDetailPage(device: device,
                             currency: currency,
                             onDelete: { confirmingDelete = device })
        } else {
            emptyState
        }
    }
}

// MARK: - summary header

struct SummaryHeaderBlock: View {
    let summary: Summary?
    let currency: String
    let devices: [Device]

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
                    Text(L10n.t(.dailyCostTotal))
                        .font(.system(size: 13))
                        .foregroundStyle(PaybackTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(summary?.deviceCount ?? 0)")
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var investmentText: String {
        if let spent = summary?.group(for: currency)?.totalSpentMinor {
            return Money.major(spent, code: currency)
        }
        return Money.major(Int64(0), code: currency)
    }

    private var dailyText: String {
        if let sum = summary?.group(for: currency)?.dailyCostSumMinor {
            return Money.perDay(sum, code: currency)
        }
        return Money.perDay(Double(0), code: currency)
    }
}

// MARK: - device row

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CategoryIcon.symbol(for: device.category))
                .font(.system(size: 18))
                .foregroundStyle(device.isGoalMet ? PaybackTheme.accent : PaybackTheme.muted)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(device.isGoalMet ? PaybackTheme.soft : PaybackTheme.surface)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                    .lineLimit(2)
                Text(device.dailyCostText + L10n.t(.perDay)
                     + (device.isGoalMet ? " · " + L10n.t(.paidBack) : ""))
                    .font(.system(size: 13))
                    .foregroundStyle(device.isGoalMet ? PaybackTheme.earn : PaybackTheme.muted)
            }
            Spacer(minLength: 8)
            if device.isGoalMet {
                Circle()
                    .fill(PaybackTheme.earn)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - trash sheet

struct TrashSheet: View {
    @EnvironmentObject private var session: CompanionSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(session.trash) { device in
                HStack(spacing: 12) {
                    Image(systemName: CategoryIcon.symbol(for: device.category))
                        .foregroundStyle(PaybackTheme.muted)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text(Money.major(device.priceMinor, code: device.currency)
                             + " · " + device.purchaseDate)
                            .font(.caption)
                            .foregroundStyle(PaybackTheme.muted)
                    }
                    Spacer()
                    Button(L10n.t(.restoreButton)) {
                        Task { await session.restore(device) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.t(.trashTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t(.close)) { dismiss() }
                }
            }
            .overlay {
                if session.trash.isEmpty {
                    Text(L10n.t(.trashEmpty))
                        .foregroundStyle(PaybackTheme.muted)
                }
            }
            .task {
                await session.loadTrash()
            }
        }
        .presentationDetents([.medium, .large])
    }
}
