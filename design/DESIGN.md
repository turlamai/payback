# Payback — 视觉与交互契约

## 当前范围

2026-11-14：在既有原型上补齐设置、中英文、本地备份恢复、删除恢复与页面内自动化。保留暖纸色、橙绿语义、非模态设备分栏，以及五个页面入口。本契约是下一步原生实现对齐的设计基线，不表示产品引擎、macOS/Windows 宿主、真实同步或发行工程已经完成。

2026-11-20：Linux 桌面腿退役（#66，owner 决策 2026-11-19），原生对齐范围为 macOS + Windows；iOS/iPadOS 伴随端按 #63 推进。引擎与 contract/bridge 验收保持平台中立。

- 主入口：`index.html`。
- 五个情景入口：`prototype/library.html`、`prototype/device.html`、`prototype/empty.html`、`prototype/form.html`、`prototype/settings.html`。
- 视觉与布局：`prototype/shared.css`。
- 界面与双语文案：`prototype/app.js`。
- 当前原型数据、校验、备份及预览提交：`prototype/model.js`。

这些都是静态浏览器原型文件。浏览器内的业务计算仅用于原型；正式产品的业务逻辑必须回到 Racket 引擎，不把它作为产品壳层业务实现。

## 本轮完成边界

1. 设置固定在侧栏底部；设备列表独立滚动，详情顶部也提供设置入口。
2. 设置分为语言与外观、数据与恢复、Agent 与自动化、关于四组。
3. 中英文覆盖导航、详情、表单、弹窗、错误和反馈。支持跟随系统、简体中文、English，偏好随本地状态保存。金额、数字及日期随界面语言格式化，记录名称和备注不翻译。机器字段和错误码不翻译。
4. 外观支持跟随系统、浅色、深色；默认货币用于新增和同币种汇总，不换算既有记录。
5. 可导出 JSON 备份、校验并确认恢复、查看与恢复最近删除。删除后显示撤销操作；最近删除不会自动清空。
6. 自动化查询与界面共用同一份数据。写入默认关闭，仅本次页面有效；预览不产生写入，显式提交才修改。
7. 真实同步、正式产品 CLI、MCP、原生数据库、授权与发行工程不在本轮范围。页面明确说明这些边界。
8. 未开展本轮浏览器视觉预览、截图或运行验收；此前 UI 访问受限，不据此宣称布局与流程经过实机验证。

## 产品表达与信息层级

核心问题为“现在每天成本多少”和“距离个人价值目标还有多久”。金额与倒计时优先，曲线、里程碑、说明与备注其次。

“回本”仅指用户自定的累计使用价值达到购买价格，不代表收入、真实盈利、折旧或转售价值。不使用“已赚回”包装主观计算。英文使用 personal value goal / goal met。

设备名称在列表可省略，选中后在详情完整换行。核心金额不拆行；窄窗口把核心指标纵向排列。成本曲线是真正计算的 SVG，图标是统一线性分类符号，不声称是设备真实外观。

设置的产品信息使用人能理解的语言，不显示引擎实现细节。技术调用示例只放在用户主动打开的自动化说明中。

## 视觉规范

所有视觉 token 集中在 `prototype/shared.css`。暖纸色延续既有品牌，不作为无品牌项目的默认背景。

| Token | 浅色 | 深色 |
| --- | --- | --- |
| paper | `#FAF7F2` | `#211F1C` |
| surface | `#FFFFFF` | `#2B2926` |
| sidebar | `#F2EDE6` | `#25221F` |
| ink | `#302D29` | `#EEE9E2` |
| muted | `#68635C` | `#B9B1A7` |
| line | `#E1DCD4` | `#47413B` |
| accent | `#A64A2B` | `#E5A17E` |
| accent-hover | `#913E23` | `#EFB596` |
| soft | `#F3E5DC` | `#423127` |
| earn | `#276D3B` | `#8BC79B` |
| earn-soft | `#E7F0E7` | `#293B2D` |
| danger | `#B32C28` | `#FF9B92` |

- 正文 16px，辅助正文 14px，元信息 13px；12px 只用于原型索引和语言缩写。
- 系统字体栈；金额用 tabular-nums。主金额根据窗口宽度调整，不使用外部字体服务。
- 间距以 8 / 16 / 24 / 32 / 40 / 64px 为主体，主要表面圆角 16px。
- 绿色只表达目标达成及相应收益语义，橙色用于进行态与主操作，危险操作用独立红色。
- 统一 24 单位线性图标与 1.6 描边，功能 SVG 使用 `.od-icon`。
- 使用正常文档流、flex/grid；侧栏与详情分别滚动。顶栏 sticky，仍保留自己的布局空间。
- 深浅色独立取值，所有状态同时有文字或图形提示，不靠颜色独传信息。
- 可见键盘焦点、原生 dialog、明确关闭与返回路径。禁用装饰动效，尊重 reduced-motion。
- 768px 以下列表与详情分层，详情有返回操作；顶部设置入口始终可达。768–1100px 详情核心指标纵排，避免分栏压缩。

## 计算不变式

- 持有天数：按本地日历日期计算，包含购买当天，至少一天。不可录入未来购买日期。
- 每日成本 = 购买价格 ÷ 持有天数。
- 目标天数 = ceil(购买价格 ÷ 每日价值)。剩余天数至少为零，进度最多 100%。
- 超过成本的个人使用价值 = max(0, 持有天数 × 每日价值 − 购买价格)。
- 关闭目标时 daily = null，不显示虚构倒计时或进度。
- 修改每日价值会重新计算整个持有期，界面明确解释。
- 汇总不混算币种；每日成本排序按币种分组，同组数值降序。
- 所有派生指标来自当前模型，不为列表、详情或图表分别硬编码数值。

## 数据与存储

### 当前页面与现有记录

沿用此前浏览器存储键，读取旧结构后在内存归一化；首次修改时写入新结构。主设备库与空库情景使用不同存储键，不互相覆盖。文件路径或预览来源变化时浏览器存储可能不同，跨来源迁移使用备份。

所有输入先校验，再修改模型。设备名称 1–120 字符；价格和非空每日金额大于零、不超过 10,000,000，最多两位小数；购买日期在 1900-01-01 与今天之间；备注最多 2,000 字符。支持列举的 12 种货币。设备与最近删除各最多 2,000 条，列表每次加载 50 条。

存储不可用时维持内存状态，返回 persisted=false，页面显示“仅本次会话”并提供备份入口，不伪称已持久保存。无效原始存储不会被普通编辑覆盖；保留下载原始数据入口，只允许用户明确选择的有效备份替换它。

提交前对照当前浏览器存储内容。发现其他页面已修改时返回 EXTERNAL_CHANGE，不静默覆盖；提示先导出本次会话、再重新加载。这个机制不等于完整多进程数据库锁，正式产品需要由引擎提供事务与并发控制。

### 保存生命周期

表单失焦校验，保存时校验全部字段并聚焦首错。Enter 与按钮执行相同路径，备注 Enter 正常换行。保存中禁用字段与关闭入口，拒绝重复提交；失败保持输入，提供重试。成功后选中新设备并重新派生汇总与详情。持久化失败时也明确区分本次会话的成功修改与未落盘状态。

### 删除与恢复

删除确认显示设备全名与可恢复后果。确认后移动至最近删除，记录 ID 不变；撤销恢复原记录，亦可在设置中恢复。恢复仍使用统一校验与提交。没有清空最近删除或永久删除操作。

### 备份

下载格式为未加密 JSON，文件名包含日期。下载动作只宣称已发起下载，浏览器是否完成保存由用户确认。自动化接口也能返回结构化备份，不依赖下载能力。

格式：

```json
{
  "schema": "payback.backup",
  "version": 1,
  "createdAt": "ISO-8601",
  "data": {
    "devices": [],
    "trash": [],
    "preferences": {
      "currency": "CNY",
      "theme": "system",
      "language": "system"
    }
  }
}
```

导入最多 5 MB。检查版本、结构、记录字段与 ID 全局唯一性，全部通过才展示预览。恢复会替换当前设备、最近删除与偏好；预览显示替换数量、导入数量和最近删除数量，提供“先备份当前数据”操作。必须明确确认才提交。任何校验失败不更改当前数据。恢复不会开启自动化写入。

## 页面内自动化

### 能力与边界

入口为 `window.paybackAgent`，面向能执行页面脚本的 agent。其输出不依赖界面语言、文案或 DOM 排布。该对象只属于当前浏览器页面，没有 HTTP 服务、CLI、MCP 或跨设备能力。

任何同页脚本都可能访问该对象；写入开关只是用户意图控制，不构成鉴权、恶意代码隔离或正式产品权限系统。开关默认关闭、刷新重置、不写入备份。正式原生产品还需要 Racket 引擎 API、CLI/MCP、授权、审计及持久幂等机制。

### 方法

| 方法 | 作用 |
| --- | --- |
| describe() | 版本、字段约束、动作、许可与限制 |
| list() | 设备和当前派生指标的副本 |
| get(id) | 用稳定 ID 查询设备 |
| summary(currency?) | 同币种汇总与当前 revision |
| exportBackup() | 返回备份对象，不触发下载 |
| preview(request) | 校验并返回影响和提交标识，不写入 |
| commit(token) | 在许可开启时提交先前预览 |

返回统一为 `{ ok: true, data: ... }` 或 `{ ok: false, error: { code, fields? } }`。错误码稳定不翻译；界面把相同错误码映射为中英文。

支持动作：create、update、delete、restore、preferences、import。新记录由模型生成 ID；更新和恢复保留 ID，更新不能改写 ID。只有列举的字段允许写入。

```js
window.paybackAgent.list();
window.paybackAgent.get('mac');

// Close UI dialogs and enable automation writes in Settings first.
const preview = window.paybackAgent.preview({
  action: 'update',
  id: 'mac',
  patch: { daily: 25 }
});
// Inspect preview.data.effect before explicitly committing.
const result = window.paybackAgent.commit(preview.data.token);
```

预览 5 分钟有效，绑定当前 revision。任何成功修改都会让旧预览失效；表单或其他模态打开时拒绝自动化预览与提交，避免编辑期间并发写入。最多保留 100 个待提交预览，及最近 100 个成功提交的返回值；在本次页面生命周期内，重复提交已完成 token 返回原结果，不重复写入。刷新后不保留 token 或幂等缓存，不承诺跨重载的幂等性。

备份恢复使用相同预览提交链，导入成功重置自动化写入许可。UI 和 agent 的修改共享模型、校验、revision、计算和可恢复删除规则；查询返回副本，不暴露可直接修改的内部状态。

## 原生产品后续门槛

本轮不把原型当成正式产品发布完成。下一阶段需要对齐 macOS/Windows 原生界面和共享文案，接入正式持久化与同步，落实 Racket 引擎与 CLI/MCP 契约，并完成可访问性、窗口缩放、完整读写与恢复、并发、安装升级和发行门禁。原型落账到 git 仓 `design/` 后，宿主才能按此基线实施。


## Prototype source checkpoint — 2026-11-15

`index.html` opens the primary prototype directly. Screen-directory launchers have been removed. All local scripts, styles and referenced assets needed by this checkpoint are versioned under this directory; OpenDesign metadata is excluded. This is an editable prototype checkpoint, not a claim that the native product or external services implement these interactions.

## 原生实现映射（2026-11-18 声明，#57）

原型是设计契约；存储词汇以 `docs/data-format.md` 为准，两处的对齐规则如下：

- **分类**：引擎存 10 个分类值；宿主表单只列原型的 7 个展示项，映射
  `keyboard→accessory`、`coffee→appliance`、`box→other`（标签按原型文案）。存量
  `watch`/`camera`/`gaming` 记录在编辑表单中保留原值（带本地化标签），保存绝不静默改写。
  图标一律线性线风格，与原型 `icons` 集合一致。
- **术语**：全部 UI 文案弃用「已赚回/earned」表述；「回本」= 个人使用价值目标（英文
  personal value goal / goal met）。引擎 wire 键名不变（存储名 ≠ 用户文案）。
- **汇总区**：设备投入 + 合计每日成本 + 记录中的设备三项；静态说明行取代旧轮换 quip。
- **原型外的保留面（已声明）**：更新检查/安装流程（家族基线）、里程碑庆祝浮层（引擎
  ack-on-read 能力，按新 token 重绘）、每日快报通知（文案改为目标语义）。
- **数据边界**：备份恢复后，当前多余墓碑保留在最近删除（同步安全语义，见
  `docs/sync-design.md`）；原型里的浏览器自动化接口（`window.paybackAgent`）是原型专用，
  原生产品的 CLI/MCP 面另行立项，不在本轮范围。
