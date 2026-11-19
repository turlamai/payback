import SwiftUI

// Detail pane per the 2026-11 prototype (design/prototype/app.js
// renderDetail): device head with actions, the hero (daily cost + personal
// value goal), the cost curve, milestones, the method explainer, notes.
// Amounts and derived values come from the engine's computed block; the
// host only formats and lays out.

func paybackDetailProbe(_ tag: String) -> EmptyView {
    if ProcessInfo.processInfo.environment["PAYBACK_E2E"] == "1" {
        FileHandle.standardError.write(Data("payback: render detail.\(tag)\n".utf8))
    }
    return EmptyView()
}

struct DeviceDetail: View {
    let device: Device
    let currency: String
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        paybackDetailProbe("body")
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                deviceHead
                hero
                chartSection
                bottomGrid
                if let notes = device.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)
            .padding(.bottom, 56)
            .frame(maxWidth: 1120, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(PaybackTheme.paper)
    }

    // MARK: head

    @ViewBuilder
    private var deviceHead: some View {
        paybackDetailProbe("head")
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(CategoryLabel.label(for: device.category)) · "
                     + L10n.t(.daysTogether)
                        .replacingOccurrences(of: "{days}",
                                              with: formattedDays(device.computed.daysHeld)))
                    .font(.system(size: 13, weight: .semibold))
                    .kerning(0.6)
                    .foregroundStyle(PaybackTheme.muted)
                Text(device.name)
                    .font(.system(size: 28, weight: .semibold))
                    .kerning(-0.7)
                    .foregroundStyle(PaybackTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Money.major(device.priceMinor, code: device.currency)
                     + " · " + L10n.t(.purchasedOn) + " " + formattedDate(device.purchaseDate))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
            }
            Spacer(minLength: 16)
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15))
                }
                .help(L10n.t(.edit))

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundStyle(PaybackTheme.danger)
                }
                .help(L10n.t(.delete))
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: hero

    /// the prototype's .hero: left = today's daily cost, right = the
    /// personal value goal. Stacks vertically on narrow windows
    /// (768–1100px contract in DESIGN.md).
    @ViewBuilder
    private var hero: some View {
        paybackDetailProbe("hero")
        // horizontal at the window floor; the stacked variant only matters
        // below the 768px breakpoint, which the macOS window never reaches
        HStack(alignment: .top, spacing: 32) {
            heroLeft
            Divider()
            heroRight
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: PaybackTheme.cardCorner, style: .continuous)
                .fill(PaybackTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PaybackTheme.cardCorner, style: .continuous)
                .strokeBorder(PaybackTheme.line, lineWidth: 1)
        )
        .padding(.bottom, 24)
    }

    private var heroLeft: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t(.heroDailyLabel))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PaybackTheme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Money.perDay(device.computed.costPerDayMinor, code: device.currency))
                    .font(.system(size: 52, weight: .semibold))
                    .kerning(-1.5)
                    .monospacedDigit()
                    .foregroundStyle(PaybackTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(L10n.t(.perDay))
                    .font(.system(size: 16))
                    .foregroundStyle(PaybackTheme.muted)
            }
            .padding(.top, 12)
            Text(L10n.t(.heroDailyCaption))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var heroRight: some View {
        let computed = device.computed
        if computed.willingSet {
            VStack(alignment: .leading, spacing: 0) {
                Text(computed.paidBack
                     ? L10n.t(.goalMetHeading)
                     : L10n.t(.goalRemainingHeading))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PaybackTheme.muted)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if computed.paidBack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                            Text(L10n.t(.paidBack))
                                .font(.system(size: 32, weight: .semibold))
                                .kerning(-0.7)
                        }
                        .foregroundStyle(PaybackTheme.earn)
                    } else {
                        Text(formattedDays(remainingDays))
                            .font(.system(size: 32, weight: .semibold))
                            .kerning(-0.7)
                            .monospacedDigit()
                            .foregroundStyle(PaybackTheme.accent)
                        Text(L10n.t(.days))
                            .font(.system(size: 16))
                            .foregroundStyle(PaybackTheme.muted)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                // plain native bar: a GeometryReader-driven fill forces a
                // Metal compositing pass on the GPU-less x64 CI runner
                // (issue #64)
                ProgressView(value: min(max(computed.paybackProgress ?? 0, 0), 1))
                    .progressViewStyle(.linear)
                    .tint(computed.paidBack ? PaybackTheme.earn : PaybackTheme.accent)
                    .padding(.top, 14)
                .accessibilityElement()
                .accessibilityLabel(Text(L10n.t(.paybackProgress)))
                .accessibilityValue(Text(String(
                    format: "%.0f%%", min(max(computed.paybackProgress ?? 0, 0), 1) * 100)))
                Text(L10n.t(.goalBasedOn)
                    .replacingOccurrences(
                        of: "{amount}",
                        with: Money.major(device.willingPerDayMinor ?? 0,
                                          code: device.currency)))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
                    .padding(.top, 12)
                if computed.paidBack, let earned = computed.earnedMinor {
                    Text(L10n.t(.goalExtra)
                        .replacingOccurrences(
                            of: "{amount}",
                            with: Money.major(max(earned, 0), code: device.currency)))
                        .font(.system(size: 14))
                        .foregroundStyle(PaybackTheme.muted)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // no goal set: the prototype's goal-question panel
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.t(.goalMetHeading))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PaybackTheme.muted)
                Text(L10n.t(.goalQuestion))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                    .padding(.top, 12)
                Text(L10n.t(.goalSetHint))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
                    .padding(.top, 8)
                Button(action: onEdit) {
                    HStack(spacing: 8) {
                        Text(L10n.t(.setDailyValue))
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(PaybackTheme.accent)
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// remaining days to the goal: ⌈price/willing⌉ − held, floored at 0 —
    /// derived from the engine's own values only (display arithmetic on
    /// already-computed numbers, mirroring the prototype)
    private var remainingDays: Int64 {
        let computed = device.computed
        guard let eta = computed.paybackEta else { return 0 }
        return max(0, Self.daysBetween(device.purchaseDate, eta)
                     - Int64(computed.daysHeld))
    }

    static func daysBetween(_ from: String, _ to: String) -> Int64 {
        guard let f = parseDate(from), let t = parseDate(to) else { return 0 }
        return Int64(Calendar(identifier: .gregorian)
            .dateComponents([.day], from: f, to: t).day ?? 0)
    }

    private static func parseDate(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    // MARK: chart

    @ViewBuilder
    private var chartSection: some View {
        paybackDetailProbe("curve")
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.t(.chartTitle))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                Spacer()
                Text(L10n.t(.chartSubtitle)
                    .replacingOccurrences(of: "{days}",
                                          with: formattedDays(device.computed.daysHeld)))
                    .font(.system(size: 13))
                    .foregroundStyle(PaybackTheme.muted)
            }
            .padding(.bottom, 20)
            CostCurve(priceMinor: device.priceMinor,
                      daysHeld: Int(device.computed.daysHeld))
                .accessibilityLabel(Text(L10n.t(.chartA11y)
                    .replacingOccurrences(
                        of: "{cost}",
                        with: Money.perDay(device.computed.costPerDayMinor,
                                           code: device.currency))))
            HStack {
                Text(L10n.t(.chartDayOne)
                    .replacingOccurrences(
                        of: "{amount}",
                        with: Money.major(device.priceMinor, code: device.currency)))
                Spacer()
                Text(L10n.t(.chartToday)
                    .replacingOccurrences(
                        of: "{amount}",
                        with: Money.perDay(device.computed.costPerDayMinor,
                                           code: device.currency)))
            }
            .font(.system(size: 13))
            .foregroundStyle(PaybackTheme.muted)
            .padding(.top, 8)
            Text(L10n.t(.chartNote))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 12)
        }
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PaybackTheme.line)
                .frame(height: 1)
        }
    }

    // MARK: bottom grid

    private var bottomGrid: some View {
        // fixed two-column at the desktop width (the 768-1100 stacked rule
        // is a browser-only breakpoint; see the comment on `hero`)
        HStack(alignment: .top, spacing: 40) {
            milestoneSection.frame(maxWidth: .infinity, alignment: .leading)
            methodSection.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 32)
    }

    @ViewBuilder
    private var milestoneSection: some View {
        paybackDetailProbe("milestones")
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.t(.milestonesTitle))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                Spacer()
                Text("\(achievedCount) / 3")
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
            }
            .padding(.bottom, 4)
            // the prototype's ladder: only the three days-together
            // milestones on the main list; cost thresholds live in the
            // disclosure below
            ForEach(dayMilestones, id: \.key) { milestone in
                MilestoneRow(milestone: milestone,
                             daysHeld: device.computed.daysHeld)
            }
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(costMilestones, id: \.key) { milestone in
                        Text(costMilestoneLine(milestone))
                            .font(.system(size: 14))
                            .foregroundStyle(PaybackTheme.muted)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(L10n.t(.costMilestonesTitle))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PaybackTheme.ink)
            }
            .tint(PaybackTheme.accent)
            .padding(.top, 20)
        }
        .padding(.top, 8)
    }

    private var dayMilestones: [Milestone] {
        device.computed.milestones.filter { isDayMilestone($0.key) }
    }

    private var costMilestones: [Milestone] {
        device.computed.milestones.filter { !isDayMilestone($0.key) }
    }

    private var achievedCount: Int {
        device.computed.milestones
            .filter { isDayMilestone($0.key) && $0.achieved }
            .count
    }

    private func isDayMilestone(_ key: String) -> Bool {
        key.hasPrefix("days-")
    }

    private func isCostMilestone(_ key: String) -> Bool {
        key.hasPrefix("cpd-")
    }

    private func costMilestoneLine(_ milestone: Milestone) -> String {
        let amount = Self.cpdMilestoneAmount(milestone.key)
        let threshold = Money.major(Int64(amount * 100), code: device.currency)
        let status = milestone.achieved
            ? L10n.t(.milestoneReached)
            : L10n.t(.costMilestoneNotYet)
        return status + " · "
            + L10n.t(.costMilestoneBelow)
                .replacingOccurrences(of: "{amount}", with: threshold)
    }

    /// thresholds in major units, matching the engine's cpd ladder
    /// (cpd-10 = below 10.00 major per day, docs/data-format.md)
    static func cpdMilestoneAmount(_ key: String) -> Double {
        switch key {
        case "cpd-10": return 10
        case "cpd-5": return 5
        case "cpd-2": return 2
        case "cpd-1": return 1
        case "cpd-05": return 0.5
        default: return 0
        }
    }

    @ViewBuilder
    private var methodSection: some View {
        paybackDetailProbe("method")
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t(.methodTitle))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t(.methodIntro1))
                Text(L10n.t(.methodIntro2))
            }
            .font(.system(size: 14))
            .foregroundStyle(PaybackTheme.muted)
            .padding(.top, 8)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t(.methodCalcDays))
                    Text(L10n.t(.methodCalcReset))
                }
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 8)
            } label: {
                Text(L10n.t(.methodCalcTitle))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PaybackTheme.ink)
            }
            .tint(PaybackTheme.accent)
            .padding(.top, 16)
        }
        .padding(.top, 8)
    }

    // MARK: notes

    private func notesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t(.notesTitle))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 32)
    }

    // MARK: formatting

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = L10n.prefersChinese
            ? Locale(identifier: "zh-CN") : Locale(identifier: "en_US")
        return formatter
    }

    private func formattedDate(_ text: String) -> String {
        guard let date = Self.parseDate(text) else { return text }
        return dateFormatter.string(from: date)
    }

    private func formattedDays(_ days: Int64) -> String {
        let value = Int(days)
        if L10n.prefersChinese {
            return NumberFormatter.localizedString(from: NSNumber(value: value),
                                                   number: .decimal)
        }
        return NumberFormatter.localizedString(from: NSNumber(value: value),
                                               number: .decimal)
    }
}

// MARK: - milestone row

/// Prototype .milestone: check (reached) or chevron (future), the
/// days-together label, and the reached/days-to-go suffix.
struct MilestoneRow: View {
    let milestone: Milestone
    let daysHeld: Int64

    var body: some View {
        HStack(spacing: 12) {
            if milestone.achieved {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PaybackTheme.earn)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PaybackTheme.muted)
            }
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(milestone.achieved
                                 ? PaybackTheme.ink : PaybackTheme.muted)
            Spacer(minLength: 8)
            Text(suffix)
                .font(.system(size: 13))
                .foregroundStyle(milestone.achieved
                                 ? PaybackTheme.earn : PaybackTheme.muted)
        }
    }

    private var label: String {
        switch milestone.key {
        case "days-100":
            return L10n.t(.daysTogether)
                .replacingOccurrences(of: "{days}", with: "100")
        case "days-365":
            return L10n.t(.daysTogether)
                .replacingOccurrences(of: "{days}", with: "365")
        case "days-1000":
            return L10n.t(.daysTogether)
                .replacingOccurrences(of: "{days}", with: "1,000")
        case "paid-back":
            return L10n.t(.milestonePaidBack)
        default:
            return MilestoneBadge.label(for: milestone.key)
        }
    }

    private var suffix: String {
        if milestone.achieved { return L10n.t(.milestoneReached) }
        guard let target = Self.dayTargets[milestone.key], target > 0 else {
            return L10n.t(.costMilestoneNotYet)
        }
        let remaining = max(target - Int(daysHeld), 1)
        let formatted = NumberFormatter.localizedString(
            from: NSNumber(value: remaining), number: .decimal)
        return L10n.t(.milestoneDaysToGo)
            .replacingOccurrences(of: "{days}", with: formatted)
    }

    /// day thresholds for the days-together ladder (docs/data-format.md)
    static let dayTargets: [String: Int] = [
        "days-100": 100, "days-365": 365, "days-1000": 1000
    ]
}

// MARK: - cost curve

/// The daily-cost curve: cost(day) = price / day, normalized against day
/// one (= the full price), exactly the prototype's mapping
/// y = top + (1 − 1/day) × span. It only ever falls — that is the product.
///
/// Rendered as Shapes over a GeometryReader, deliberately not a SwiftUI
/// `Canvas`: Canvas draws through Metal on macOS, and the GPU-less Intel
/// CI runner aborts inside MTLLoader when a device is requested
/// (issue #64). Shapes rasterize on the Core Graphics path the
/// pre-redesign host used and that runner runs fine.
struct CostCurve: View {
    let priceMinor: Int64
    let daysHeld: Int

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let insetX: CGFloat = 8
            let insetY: CGFloat = 8
            let span = size.height - insetY * 2 - 10
            let width = size.width - insetX * 2

            // dashed axes: midline + baseline, like the prototype
            CostCurveAxes(width: width, span: span)
                .stroke(PaybackTheme.line,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                .frame(width: size.width, height: size.height)
                .offset(x: 0, y: 0)

            // the curve's area fill and its line
            CostCurveFill(width: width, span: span, daysHeld: daysHeld)
                .fill(PaybackTheme.soft)
                .frame(width: size.width, height: size.height)
            CostCurveLine(width: width, span: span, daysHeld: daysHeld)
                .stroke(PaybackTheme.accent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                           lineJoin: .round))
                .frame(width: size.width, height: size.height)

            // the "today" dot at the curve's end
            let held = Double(max(daysHeld, 1))
            Circle()
                .fill(PaybackTheme.accent)
                .frame(width: 8, height: 8)
                .position(x: insetX + width,
                          y: insetY + CGFloat(1 - 1 / held) * span)
        }
        .frame(height: 180)
    }
}

/// Shared curve geometry: the falling daily-cost polyline from day one
/// (= the whole price) toward today.
private func costCurveLinePath(width: CGFloat, span: CGFloat,
                               daysHeld: Int) -> Path {
    let insetX: CGFloat = 8
    let insetY: CGFloat = 8
    let held = max(daysHeld, 1)
    var line = Path()
    let samples = 65
    for index in 0..<samples {
        let fraction = Double(index) / Double(samples - 1)
        let day = 1.0 + fraction * Double(held - 1)
        let x = insetX + CGFloat(fraction) * width
        let y = insetY + CGFloat(1 - 1 / day) * span
        let point = CGPoint(x: x, y: y)
        if index == 0 {
            line.move(to: point)
        } else {
            line.addLine(to: point)
        }
    }
    return line
}

private struct CostCurveAxes: Shape {
    let width: CGFloat
    let span: CGFloat

    func path(in rect: CGRect) -> Path {
        let insetX: CGFloat = 8
        let insetY: CGFloat = 8
        var axis = Path()
        axis.move(to: CGPoint(x: insetX, y: insetY + span * 0.5))
        axis.addLine(to: CGPoint(x: width + insetX, y: insetY + span * 0.5))
        axis.move(to: CGPoint(x: insetX, y: insetY + span))
        axis.addLine(to: CGPoint(x: width + insetX, y: insetY + span))
        return axis
    }
}

private struct CostCurveLine: Shape {
    let width: CGFloat
    let span: CGFloat
    let daysHeld: Int

    func path(in rect: CGRect) -> Path {
        costCurveLinePath(width: width, span: span, daysHeld: daysHeld)
    }
}

private struct CostCurveFill: Shape {
    let width: CGFloat
    let span: CGFloat
    let daysHeld: Int

    func path(in rect: CGRect) -> Path {
        let insetX: CGFloat = 8
        let insetY: CGFloat = 8
        var fill = costCurveLinePath(width: width, span: span,
                                     daysHeld: daysHeld)
        fill.addLine(to: CGPoint(x: width + insetX, y: insetY + span))
        fill.addLine(to: CGPoint(x: insetX, y: insetY + span))
        fill.closeSubpath()
        return fill
    }
}
