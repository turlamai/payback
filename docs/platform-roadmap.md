# Payback platform scope

**English** · [简体中文](platform-roadmap.zh-CN.md)

## Current scope

Maintain the macOS SwiftUI and Windows WinUI 3 desktop hosts over the existing Racket domain and RVT1 contract. The iOS/iPadOS SwiftUI companion (`ios/PaybackCompanion`, CompanionSession / RVT1 pairing) is in development per [#63](https://github.com/turlamai/payback/issues/63) and not yet delivered. The Linux GTK4 desktop leg was retired on 2026-11-20 ([#66](https://github.com/turlamai/payback/issues/66), owner decision 2026-11-19); the engine and its contract/bridge acceptance suites stay platform-neutral and keep running on Linux machines in CI. Published assets are previews; CI builds are not independent hardware/UI qualification. The public [user guide](USER-GUIDE.md) records current installation, data and privacy limitations.

## Next work

Keep the bounded sync queue in [#9](https://github.com/turlamai/payback/issues/9) and its semantics in [sync-design.md](sync-design.md). Align free behavior in [#20](https://github.com/turlamai/payback/issues/20) and group money by currency in [#23](https://github.com/turlamai/payback/issues/23). The GTK date-input defect [#22](https://github.com/turlamai/payback/issues/22) is superseded by the Linux retirement (#66). These issues are acceptance work, not claims that existing builds are fixed.

## Mobile companion (in development)

The iOS/iPadOS companion is an active workstream (#63): RVT1 pairing has shipped; delivery still requires its own CI build slot, packaging, signing, device and product evidence. No watch or Android client is a current delivery or a sale. Runtime/embedding feasibility remains owned by [Rivet's delivery plan](https://github.com/turlamai/rivet/blob/main/docs/desktop-closeout-mobile-plan.md); do not introduce an ad-hoc RVT-lite protocol or duplicate the domain in Swift/Kotlin from this historical plan. Any future platform requires its own generated host, packaging, signing, device and product evidence.

## Commercial boundary

Payback is an active commercialization workstream — the family's full-platform payment-flow validation product (macOS / Windows / iOS / iPadOS) — per [PORTFOLIO.md](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.md) (2026-11-19). Its own PRICING decision must land before any purchase flow ships; until then every delivered platform is free, and no mobile presale, device cap or sync/export paywall is implemented. The old all-platform buyout and independent mobile-core proposal are retired; their text remains in Git history.