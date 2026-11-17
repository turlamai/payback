import SwiftUI

// Device detail per the 2026-11 prototype: hero (daily cost + goal),
// cost curve, milestones, method. The hero stacks vertically on compact
// width and sits side by side on regular width (DESIGN.md responsive rule).

struct DeviceDetailPage: View {
    let device: Device
    let currency: String
    var onDelete: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                head
                hero
                chartSection
                milestoneSection
                methodSection
                if let notes = device.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(PaybackTheme.paper)
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: head

    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(CategoryLabel.label(for: device.category)) · "
                 + L10n.t(.daysTogether)
                    .replacingOccurrences(of: "{days}",
                                          with: formattedDays(device.computed.daysHeld)))
                .font(.system(size: 13, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(PaybackTheme.muted)
            Text(device.name)
                .font(.system(size: 26, weight: .semibold))
                .kerning(-0.7)
                .foregroundStyle(PaybackTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(Money.major(device.priceMinor, code: device.currency)
                 + " · " + L10n.t(.purchasedOn) + " " + formattedDate(device.purchaseDate))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
    }

    // MARK: hero

    private var hero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                heroLeft
                Rectangle()
                    .fill(PaybackTheme.line)
                    .frame(width: 1)
                heroRight
            }
            VStack(alignment: .leading, spacing: 20) {
                heroLeft
                Rectangle()
                    .fill(PaybackTheme.line)
                    .frame(height: 1)
                heroRight
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PaybackTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 44, weight: .semibold))
                    .kerning(-1.5)
                    .monospacedDigit()
                    .foregroundStyle(PaybackTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(L10n.t(.perDay))
                    .font(.system(size: 15))
                    .foregroundStyle(PaybackTheme.muted)
            }
            .padding(.top, 10)
            Text(L10n.t(.heroDailyCaption))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 10)
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
                if computed.paidBack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                        Text(L10n.t(.paidBack))
                            .font(.system(size: 28, weight: .semibold))
                            .kerning(-0.7)
                    }
                    .foregroundStyle(PaybackTheme.earn)
                    .padding(.top, 10)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedDays(remainingDays))
                            .font(.system(size: 28, weight: .semibold))
                            .kerning(-0.7)
                            .monospacedDigit()
                            .foregroundStyle(PaybackTheme.accent)
                        Text(L10n.t(.days))
                            .font(.system(size: 15))
                            .foregroundStyle(PaybackTheme.muted)
                    }
                    .padding(.top, 10)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(PaybackTheme.line)
                        Capsule()
                            .fill(computed.paidBack ? PaybackTheme.earn : PaybackTheme.accent)
                            .frame(width: geometry.size.width
                                   * CGFloat(min(max(computed.paybackProgress ?? 0, 0), 1)))
                    }
                }
                .frame(height: 6)
                .padding(.top, 14)
                Text(L10n.t(.goalBasedOn)
                    .replacingOccurrences(
                        of: "{amount}",
                        with: Money.major(device.willingPerDayMinor ?? 0,
                                          code: device.currency)))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
                    .padding(.top, 10)
                if computed.paidBack, let earned = computed.earnedMinor {
                    Text(L10n.t(.goalExtra)
                        .replacingOccurrences(
                            of: "{amount}",
                            with: Money.major(max(earned, 0), code: device.currency)))
                        .font(.system(size: 14))
                        .foregroundStyle(PaybackTheme.muted)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.t(.goalMetHeading))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PaybackTheme.muted)
                Text(L10n.t(.goalQuestion))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                    .padding(.top, 10)
                Text(L10n.t(.goalSetHint))
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

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

    static func parseDate(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    // MARK: chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.t(.chartTitle))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                Spacer()
                Text(L10n.t(.chartSubtitle)
                    .replacingOccurrences(of: "{days}",
                                          with: formattedDays(device.computed.daysHeld)))
                    .font(.system(size: 13))
                    .foregroundStyle(PaybackTheme.muted)
            }
            .padding(.bottom, 16)
            CompanionCostCurve(priceMinor: device.priceMinor,
                               daysHeld: Int(device.computed.daysHeld))
                .frame(height: 150)
                .padding(.bottom, 8)
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
            Text(L10n.t(.chartNote))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .padding(.top, 10)
        }
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PaybackTheme.line)
                .frame(height: 1)
        }
    }

    // MARK: milestones

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.t(.milestonesTitle))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(PaybackTheme.ink)
                Spacer()
                Text("\(achievedCount) / 3")
                    .font(.system(size: 14))
                    .foregroundStyle(PaybackTheme.muted)
            }
            ForEach(device.computed.milestones.filter {
                $0.key.hasPrefix("days-")
            }, id: \.key) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: milestone.achieved ? "checkmark" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(milestone.achieved
                                         ? PaybackTheme.earn : PaybackTheme.muted)
                    Text(MilestoneDays.label(for: milestone.key))
                        .font(.system(size: 14))
                        .foregroundStyle(milestone.achieved
                                         ? PaybackTheme.ink : PaybackTheme.muted)
                    Spacer()
                    Text(milestone.achieved
                         ? L10n.t(.milestoneReached)
                         : MilestoneDays.daysToGo(milestone.key, held: device.computed.daysHeld))
                        .font(.system(size: 13))
                        .foregroundStyle(milestone.achieved
                                         ? PaybackTheme.earn : PaybackTheme.muted)
                }
            }
        }
        .padding(.top, 24)
    }

    private var achievedCount: Int {
        device.computed.milestones
            .filter { $0.key.hasPrefix("days-") && $0.achieved }
            .count
    }

    // MARK: method

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t(.methodTitle))
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            Text(L10n.t(.methodIntro1))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
            Text(L10n.t(.methodIntro2))
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private func notesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t(.notesTitle))
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(PaybackTheme.ink)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(PaybackTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    // MARK: formatting

    private func formattedDate(_ text: String) -> String {
        guard let date = Self.parseDate(text) else { return text }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = L10n.prefersChinese
            ? Locale(identifier: "zh-CN") : Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private func formattedDays(_ days: Int64) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: days),
                                        number: .decimal)
    }
}

/// days-together milestone labels + the days-to-go arithmetic, shared by
/// the list rows (same ladder as the engine: 100 / 365 / 1000)
enum MilestoneDays {
    static let targets: [String: Int] = [
        "days-100": 100, "days-365": 365, "days-1000": 1000
    ]

    static func label(for key: String) -> String {
        switch key {
        case "days-100": return L10n.t(.daysTogether).replacingOccurrences(of: "{days}", with: "100")
        case "days-365": return L10n.t(.daysTogether).replacingOccurrences(of: "{days}", with: "365")
        case "days-1000": return L10n.t(.daysTogether).replacingOccurrences(of: "{days}", with: "1,000")
        default: return key
        }
    }

    static func daysToGo(_ key: String, held: Int64) -> String {
        guard let target = targets[key] else { return L10n.t(.costMilestoneNotYet) }
        let remaining = max(target - Int(held), 1)
        return L10n.t(.milestoneDaysToGo).replacingOccurrences(
            of: "{days}",
            with: NumberFormatter.localizedString(from: NSNumber(value: remaining),
                                                  number: .decimal))
    }
}

// MARK: - cost curve

/// The prototype's curve mapping: cost(day) = price/day normalized against
/// day one, soft fill, dashed midline and baseline, today dot.
struct CompanionCostCurve: View {
    let priceMinor: Int64
    let daysHeld: Int

    var body: some View {
        Canvas { context, size in
            let insetX: CGFloat = 8
            let insetY: CGFloat = 8
            let span = size.height - insetY * 2 - 8
            let width = size.width - insetX * 2

            var axis = Path()
            axis.move(to: CGPoint(x: insetX, y: insetY + span * 0.5))
            axis.addLine(to: CGPoint(x: size.width - insetX, y: insetY + span * 0.5))
            axis.move(to: CGPoint(x: insetX, y: insetY + span))
            axis.addLine(to: CGPoint(x: size.width - insetX, y: insetY + span))
            context.stroke(axis,
                           with: .color(PaybackTheme.line),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 6]))

            let held = max(daysHeld, 1)
            var line = Path()
            var fill = Path()
            let samples = 65
            for index in 0..<samples {
                let fraction = Double(index) / Double(samples - 1)
                let day = 1.0 + fraction * Double(held - 1)
                let x = insetX + CGFloat(fraction) * width
                let y = insetY + CGFloat(1 - 1 / day) * span
                let point = CGPoint(x: x, y: y)
                if index == 0 {
                    line.move(to: point)
                    fill.move(to: point)
                } else {
                    line.addLine(to: point)
                }
            }
            fill.addLine(to: CGPoint(x: size.width - insetX, y: insetY + span))
            fill.addLine(to: CGPoint(x: insetX, y: insetY + span))
            fill.closeSubpath()
            context.fill(fill, with: .color(PaybackTheme.soft))
            context.stroke(line,
                           with: .color(PaybackTheme.accent),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                              lineJoin: .round))
            let day = Double(held)
            let dot = CGPoint(x: size.width - insetX,
                              y: insetY + CGFloat(1 - 1 / day) * span)
            var circle = Path()
            circle.addEllipse(in: CGRect(x: dot.x - 4, y: dot.y - 4,
                                         width: 8, height: 8))
            context.fill(circle, with: .color(PaybackTheme.accent))
        }
    }
}
