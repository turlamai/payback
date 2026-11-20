# Payback 平台范围

[English](platform-roadmap.md) · **简体中文**

## 当前范围

维护 macOS SwiftUI 与 Windows WinUI 3 两个桌面宿主，共用现有 Racket 领域与 RVT1 契约。iOS/iPadOS SwiftUI 伴随端（`ios/PaybackCompanion`，CompanionSession / RVT1 配对）按 [#63](https://github.com/turlamai/payback/issues/63) 开发中，尚未交付。Linux GTK4 桌面腿已于 2026-11-20 退役（[#66](https://github.com/turlamai/payback/issues/66)，owner 决策 2026-11-19）；引擎与 contract/bridge 验收套件保持平台中立，CI 继续在 Linux 机器上运行。发布附件属于预览；CI 构建不等于独立实机或 UI 验收。当前安装、数据与隐私限制见[使用指南](USER-GUIDE.zh-CN.md)。

## 下一步

同步切片仍由 [#9](https://github.com/turlamai/payback/issues/9) 管理，语义见 [sync-design.md](sync-design.md)。免费行为对齐见 [#20](https://github.com/turlamai/payback/issues/20)，按币种汇总见 [#23](https://github.com/turlamai/payback/issues/23)。GTK 日期输入缺陷 [#22](https://github.com/turlamai/payback/issues/22) 已随 Linux 退役（#66）而失效。这些是待验收工作，不表示已有构建已经修复。

## 移动伴随端（开发中）

iOS/iPadOS 伴随端是进行中的工作流（#63）：RVT1 配对已落地；交付仍需自己的 CI 构建槽、打包、签名、设备与产品证据。手表与 Android 客户端不是当前交付或销售内容。运行时和嵌入可行性归 [Rivet 交付计划](https://github.com/turlamai/rivet/blob/main/docs/desktop-closeout-mobile-plan.md)，不能根据历史方案另造 RVT-lite 协议或复制 Swift/Kotlin 领域核心。未来任何平台都需要自己的生成宿主、打包、签名、设备与产品证据。

## 商业边界

按 [PORTFOLIO.zh-CN.md](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.zh-CN.md)（2026-11-19），Payback 是家族的全平台支付流程验证产品（macOS / Windows / iOS / iPadOS），属活跃商业化工作流。自身 PRICING 决策落地前不上线任何购买流程；在此之前已交付平台全部免费，不预售移动端，不实现设备数、同步或导出付费墙。旧全平台买断与独立移动核心方案已退役，原文保留在 Git 历史中。