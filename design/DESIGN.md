# Payback DESIGN.md — 视觉与交互契约（单一真源）

原型（`design/prototype/`）与实现（`macos-host/` `windows/` `linux/`）都遵循本文件；改视觉先改这里，再同步实现。
本文件承接 `docs/design.md`（现行三端视觉契约）的色板与部件规范，并物化为原型 token；数值全部提取自实现单源，保证原型 → 原生实现零翻译成本：

- macOS：`macos-host/Sources/RivetHost/PaybackTheme.swift`（色板/部件单源）
- Windows：`windows/App.xaml` ThemeDictionaries（亮暗两套 brush）
- Linux：`linux/src/main.cpp` `apply_css`（亮/暗两套 CSS，按主题名热切换）
- 信息架构与交互：`ContentView.swift`（非模态分栏）`DeviceDetail.swift` `DeviceForm.swift`（保存生命周期）`SettingsView.swift`（同步/货币）；契约 `docs/save-lifecycle.md`；文案单源 `shared/strings/strings.json`

发现待对齐：Windows 暗色 accent 实现值 `#DE8B6F` 与 `docs/design.md`/Linux 的 `#D98A66` 不一致；原型取文档值 `#D98A66`，Windows 宿主应对齐（见不变式 4 的精神：三端同值）。

## Brief（2026-11-11 试点）

- **目标**：非从零重设计。Payback 已有明确的暖纸色视觉语言（`docs/design.md`）；本原型把「设备回本」这个主角——数字、进度环、成本曲线、里程碑——按 HIG 基准打磨并锁定为可评审契约，每屏亮/暗两态都达到可直接用于对外宣传的质量。
- **原型范围**（5 屏 × 亮/暗）：
  ① 设备库主视图（英雄屏：侧栏总览 + 设备列表 + 详情窗格，回本进行态）
  ② 设备详情已回本态（earn 绿兑现态；附「未设心理价位」提示态变体）
  ③ 添加/编辑设备表单（模态 sheet：idle 态 + 保存失败态变体）
  ④ 设置（数据与同步 + 货币）
  ⑤ 空库状态（附后端启动态变体）
- **Exit 条件**：5 屏关键状态齐（空态 / 回本态 / 保存失败态 / 同步开启态）+ 交互逻辑定稿（非模态分栏、保存生命周期、删除确认）+ HIG 清单全过 + 用户评审通过。
- **不在范围**：新功能与新 RPC 面（不动 `rivet-schema.json`）、更新 sheet 与庆祝 sheet 的完整流程、删除确认对话框细节（沿用实现现状）、官网与宣传物料、移动端、新配色体系（不推翻暖纸色）。

## 设计原则（HIG 内核 · Payback 特有）

- **数字是主角**：金额、天数、百分比是每个表面的层级最高元素（原生 rounded 字形 + `monospacedDigit`）；chrome 与辅助信息永远退后，装饰不与数字争注意力。
- **橙与绿各司其职**：橙 = 进行中的价值（进度环、主按钮、成本曲线）；绿 = 已经兑现的回报（已回本/已赚回）。绿色出现即是回报，两者永不混用——产品情绪价值的全部视觉兑现就在这条配色纪律上。
- **非模态优先**：浏览与巡览零对话框（侧栏选中即详情，HIG nonmodal design）；模态只留给完成任务（新增/编辑表单）与破坏性确认（删除设备）。
- **防错一致**：保存生命周期不可绕过——保存中禁操作、失败 banner 在表单内、字段原样保留、成功恰好关闭一次；Return=保存、Esc=取消跨端一致（`docs/save-lifecycle.md`）。
- **回报可感知但克制**：里程碑 emoji 胶囊、快报一行、已回本胶囊；卡片上里程碑最多 2 枚 + 计数，庆贺集中在庆祝 sheet，不满屏撒绿。

## Tokens（语义；值不在此复制）

值类 token 真源 = `docs/design.md`（契约基线）与三端实现（`macos-host/Sources/RivetHost/PaybackTheme.swift` 色板/部件单源 · `windows/App.xaml` ThemeDictionaries · `linux/src/main.cpp` `apply_css`）；原型 `design/prototype/shared.css` 与文档值一一对应，本表只记语义。发现待对齐：Windows 暗色 accent 实现值 `#DE8B6F` 与 `docs/design.md`/Linux 的 `#D98A66` 不一致——原型取文档值，Windows 宿主应对齐（三端同值）。

| Token | 语义 |
|---|---|
| `--paper --card --hover --line` | 页面底 / 卡片（纵向渐变+浅投影）/ 悬浮选中 / 发丝边框分隔 |
| `--ink --mute` | 主/次级文字（实现端为系统 label 色 / ink 65% 透明，原型物化为固定值） |
| `--accent --accent-soft` | 品牌橙 Crail：进度环/主按钮/曲线/进行态 + 弱底（徽标/空状态/未设价位提示卡） |
| `--earn --earn-soft` | **只**用于「已回本/已赚回」状态 + 回本后 hero 卡/进度区底色 |
| `--warning` | 同步警告（网盘冲突副本等） |
| `--track` | 进度环/进度条底槽（黑 15% / 白 15%） |

分类 tint（图标徽章底色）：computer 蓝 · phone 青 · tablet 靛 · watch 薄荷 · audio 紫 · camera 橙黄 · gaming 红 · appliance 天青 · accessory 薄荷 · other = `--accent-soft`——实现为跨主题同色相、暗色提高 alpha（值见 PaybackTheme.swift）。破坏性操作（停止同步/删除）文字用系统 destructive 红、跟随平台语义色，不进品牌色板。

- **字体**：`system-ui, -apple-system, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei"`。原生实现金额/百分比用 rounded design + `monospacedDigit`（原型以 `tabular-nums` 等价；rounded 字形由原生端兑现，Web 原型不引入外部字体）。大数字 title2 bold（22px），详情名 22px/700，行标题 600（16px），次级 13px，辅助 12px。
- **圆角**：卡片 16px（continuous）· 统计 tile 14px · 列表行/控件 10px · 胶囊 999px。**间距节奏**：4/8/12/16/24。**动效**：进度环入场 0.9s easeOut，其余 120ms ease，不过度。
- **语言**：界面文案 zh/en 双源（`shared/strings/strings.json`，跟随系统语言），原型取 zh 值；改文案必须改 strings.json + 跑 `node scripts/gen-strings.js`，不手改生成物。

## 组件词汇

`SummaryTile`（总览 4 块 2×2，「已赚回」为正是 hero 卡）· `QuipLine`（✦ 回本快报一行，侧栏摘要下方，平台通道因地制宜）· `SidebarDeviceRow`（图标徽章 + 名称 + 日均 + 迷你环/里程碑 emoji 二选一）· `DeviceIconBadge`（emoji + 分类 tint 底）· `PaybackRing`（5pt 描边 accent 渐变圆头，100% 显绿勾）· `CostCurve`（超衰减曲线，渐变描边 + 底部渐变填充，**永不上扬**）· `MilestoneBadge`（emoji + 文案胶囊；卡片最多 2 枚 + 计数，详情阶梯全列 + 达成绿勾）· `EarnCapsule`（🎉 已回本）· `HintCard`（💡 未设心理价位提示，accent-soft 底）· `DeviceForm`（模态 sheet，保存生命周期 idle→saving→failed）· `ConfirmDialog`（删除确认）· `SettingsPane`（数据与同步 + 货币）· `StatusLine`（后端就绪/快报状态行）。

## 不变式

1. 绿色只出现于「已回本/已赚回」状态（`earn`/`earn-soft`）；其余一切价值表达用橙。换色即换语义，禁止复用、禁止橙绿混排。
2. 所有金额/天数/百分比用 tabular 数字且不跳动；数字是主角，辅助信息 caption + mute，永不与数字抢层级。
3. 层级克制：paper < card 两层表面 + `line` 发丝分隔；hero 态用 `earn-soft` 底色表达，不引入第三层表面、不堆阴影表达层级。
4. 亮暗成对：每屏每状态两套齐备；暗色 accent/earn 提亮、分类 tint 提高 alpha；三端 token 同值，不存在只有暗态的界面。
5. 保存生命周期跨端一致：保存中禁 Save/Cancel 且 sheet 不可关闭；失败 banner 在表单内、字段原样保留、Save 变 Retry；成功恰好关闭一次；Return=保存、Esc=取消。
6. 主操作按钮永远品牌橙底 + 对比色文字（暗色下文字转 paper 色），禁止用平台 suggested-action 强调色（防漂出契约色板）。


## 平台映射与差异声明（预钉 · 宿主实现时升级为落点表）

统一层（三平台必须一致，`design/prototype/` 原型已锁定）：信息架构、核心流程、快捷键语义、
语义色与层级词汇。因地制宜层（按平台惯例落地，不预画像素）：

| 维度 | macOS | Windows | Linux |
|---|---|---|---|
| 修饰键 | ⌘ | Ctrl | Ctrl |
| 命令入口 | 原生菜单栏 | 菜单栏/命令行内 | 菜单栏 |
| 字体 | 系统栈 + PingFang SC | 系统栈 + Microsoft YaHei | 系统栈 + Noto Sans CJK |
| 原生控件 | SwiftUI 控件 | WinUI 3 控件 | GTK4 控件 |

差异声明纪律：宿主特例必须先写进本节才能实现；未声明的宿主差异按违约处理
（案例：taskly 漂移台账 D8）。
