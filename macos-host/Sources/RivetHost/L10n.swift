import SwiftUI

// GENERATED from shared/strings/strings.json by scripts/gen-strings.js.
// Do not edit by hand: change strings.json and re-run the generator.
// Language resolution: an in-app override ("zh" / "en") wins; otherwise
// the system language decides, with zh as the fallback.

enum L10n {
    /// in-app language override; nil = follow the system. UI-set on the main
    /// actor only; nonisolated(unsafe) keeps the generated type usable from
    /// any view body without concurrency annotations.
    nonisolated(unsafe) static var override: String?

    static var prefersChinese: Bool {
        switch override {
        case "zh": return true
        case "en": return false
        default: return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
        }
    }

    static func t(_ key: Key) -> String {
        prefersChinese ? key.zh : key.en
    }

    enum Key {
        case startingBackend
        case backendReady
        case backendError
        case configError
        case appName
        case tagline
        case totalSpent
        case earnedBack
        case deviceCount
        case overallDaily
        case addDevice
        case checkUpdatesMenu
        case helpMenu
        case emptyTitle
        case emptyHint
        case sortBy
        case sortAdded
        case sortDailyCost
        case sortPayback
        case dailyCost
        case perDay
        case heldFor
        case days
        case paidBack
        case paybackProgress
        case paybackEta
        case earnedSoFar
        case stillToEarn
        case willingPerDay
        case notSet
        case milestones
        case edit
        case delete
        case deleteConfirmTitle
        case deleteConfirmText
        case cancel
        case save
        case saving
        case saveFailed
        case genericError
        case name
        case icon
        case category
        case price
        case priceRequiredHint
        case purchaseDate
        case yearField
        case monthField
        case jumpToToday
        case dateInvalidHint
        case notes
        case willingHint
        case willingLabel
        case categoryComputer
        case categoryPhone
        case categoryTablet
        case categoryWatch
        case categoryAudio
        case categoryCamera
        case categoryGaming
        case categoryAppliance
        case categoryAccessory
        case categoryOther
        case milestoneDays100
        case milestoneDays365
        case milestoneDays1000
        case milestoneCpd10
        case milestoneCpd5
        case milestoneCpd2
        case milestoneCpd1
        case milestoneCpd05
        case milestonePaidBack
        case updates
        case updateCheckTitle
        case upToDate
        case updateAvailable
        case downloadUpdate
        case downloading
        case installNow
        case installFailed
        case updateError
        case retry
        case close
        case currency
        case languageAuto
        case languageTitle
        case digestTitle
        case celebrateTitle
        case celebrateKeep
        case quip1
        case quip2
        case quip3
        case quip4
        case quip5
        case quip6
        case curveDayLabel
        case updateAvailableBody
        case updateReadyBody
        case updateInstallFailedBody
        case updateInstallNote
        case updateOpenFolder
        case digestBody
        case digestBodyBest
        case aboutMenu
        case aboutContent
        case aboutLicense
        case aboutWebsite
        case aboutReportIssue
        case settingsTitle
        case dataSyncSection
        case syncHowItWorks
        case syncStatusOff
        case syncStatusOn
        case syncEnable
        case syncDisable
        case syncDisableConfirmTitle
        case syncDisableConfirmBody
        case syncFolderLabel
        case syncChooseFolder
        case syncPickFolderTitle
        case syncDetectedTitle
        case syncDetectedBody
        case syncUseDetected
        case syncMachinesLabel
        case syncMachineNameLabel
        case syncLastMergeLabel
        case syncIgnoredWarning
        case syncOpenFolder
        case syncEnableFailed
        case currencyHint
        case investmentEyebrow
        case investmentCaption
        case dailyCostTotal
        case devicesTracked
        case mixedCurrencyNote
        case myDevices
        case sortDate
        case openSettingsHelp
        case toggleAppearance
        case preferencesBreadcrumb
        case addFirstDevice
        case emptyExample
        case daysTogether
        case purchasedOn
        case heroDailyLabel
        case heroDailyCaption
        case goalMetHeading
        case goalRemainingHeading
        case goalBasedOn
        case goalExtra
        case goalQuestion
        case goalSetHint
        case setDailyValue
        case chartTitle
        case chartSubtitle
        case chartDayOne
        case chartToday
        case chartNote
        case chartA11y
        case milestonesTitle
        case milestoneReached
        case milestoneDaysToGo
        case costMilestonesTitle
        case costMilestoneBelow
        case costMilestoneNotYet
        case methodTitle
        case methodIntro1
        case methodIntro2
        case methodCalcTitle
        case methodCalcDays
        case methodCalcReset
        case notesTitle
        case moveToDeleted
        case keepDevice
        case toastDeleted
        case undo
        case deviceRestored
        case trashTitle
        case trashIntro
        case trashEmpty
        case restoreButton
        case trashRowHelp
        case trashView
        case sectionLanguageAppearance
        case sectionDataRecovery
        case languageRowHelp
        case appearanceRowLabel
        case appearanceRowHelp
        case appearanceSystem
        case appearanceLight
        case appearanceDark
        case currencyNotConverted
        case backupExportRow
        case backupExportHelp
        case backupExportButton
        case restoreRow
        case restoreRowHelp
        case chooseBackupButton
        case syncRowLabel
        case backupCheckTitle
        case backupCheckBody
        case restoreReviewTitle
        case restoreReplacedLabel
        case restoreImportedLabel
        case restoreTrashLabel
        case restorePrefsNote
        case restoreWarning
        case restoreConfirm
        case backupFirst
        case backupInvalid
        case backupRestored
        case backupTooLarge
        case deviceSaved
        case preferencesUpdated
        case goalEnabledLabel
        case goalSectionTitle
        case dailyValue
        case dailyValueHelp
        case notesOptional
        case formNameRequired
        case formPriceRequired
        case formDateRequired
        case saveDeviceButton
        case savingShort
        case retrySave
        case companionSection
        case companionEnable
        case companionEnableHelp
        case companionStatusOn
        case companionStatusOff
        case companionOpenWindow
        case companionWindowHint
        case companionPromptTitle
        case companionPromptBody
        case companionApprove
        case companionReject
        case companionPairedLabel
        case companionRemove
        case companionEmptyPaired
        case companionFingerprint
        case companionFailed
        case companionIdle
        case companionConnecting
        case companionConfirmCode
        case companionConnected
        case companionSessionHeader
        case companionDisconnect
        case companionNearby
        case companionStopScan
        case companionScan
        case companionNoDevices
        case companionWindowOpen
        case companionWindowClosed
        case companionWindowIDField
        case companionPair
        case companionReconnect

        var zh: String {
            switch self {
            case .startingBackend: return "正在启动 Racket 引擎…"
            case .backendReady: return "Racket CS 就绪"
            case .backendError: return "后端错误"
            case .configError: return "配置错误"
            case .appName: return "Payback 回本"
            case .tagline: return "用得越久，越接近回本"
            case .totalSpent: return "累计投入"
            case .earnedBack: return "已赚回"
            case .deviceCount: return "设备"
            case .overallDaily: return "整体日均"
            case .addDevice: return "添加设备"
            case .checkUpdatesMenu: return "检查更新…"
            case .helpMenu: return "帮助"
            case .emptyTitle: return "从第一台设备开始"
            case .emptyHint: return "记下价格和购买日期，看看它的每日成本如何一点点降下来。"
            case .sortBy: return "排序"
            case .sortAdded: return "加入顺序"
            case .sortDailyCost: return "日均成本"
            case .sortPayback: return "回本进度"
            case .dailyCost: return "每日成本"
            case .perDay: return "/天"
            case .heldFor: return "已持有"
            case .days: return "天"
            case .paidBack: return "已回本"
            case .paybackProgress: return "回本进度"
            case .paybackEta: return "预计回本"
            case .earnedSoFar: return "按你的心理价位，已经多用出"
            case .stillToEarn: return "还差"
            case .willingPerDay: return "每天愿意付"
            case .notSet: return "未设置"
            case .milestones: return "里程碑"
            case .edit: return "编辑"
            case .delete: return "删除"
            case .deleteConfirmTitle: return "删除这台设备？"
            case .deleteConfirmText: return "设备将移到最近删除，记录与目标均可恢复。"
            case .cancel: return "取消"
            case .save: return "保存"
            case .saving: return "保存中…"
            case .saveFailed: return "保存失败"
            case .genericError: return "出了点问题"
            case .name: return "名称"
            case .icon: return "图标"
            case .category: return "分类"
            case .price: return "购买价格"
            case .priceRequiredHint: return "请输入大于 0 的金额"
            case .purchaseDate: return "购买日期"
            case .yearField: return "年"
            case .monthField: return "月"
            case .jumpToToday: return "回到今天"
            case .dateInvalidHint: return "按 年-月-日 填写，例如 2026-10-15"
            case .notes: return "备注"
            case .willingHint: return "设置“每天愿意付多少钱”，就能看到回本进度。"
            case .willingLabel: return "心理价位（每天）"
            case .categoryComputer: return "电脑"
            case .categoryPhone: return "手机"
            case .categoryTablet: return "平板"
            case .categoryWatch: return "手表"
            case .categoryAudio: return "音频"
            case .categoryCamera: return "相机"
            case .categoryGaming: return "游戏"
            case .categoryAppliance: return "家电"
            case .categoryAccessory: return "配件"
            case .categoryOther: return "其他"
            case .milestoneDays100: return "百日纪念"
            case .milestoneDays365: return "陪伴一整年"
            case .milestoneDays1000: return "一千天老友"
            case .milestoneCpd10: return "日均低于 10 元"
            case .milestoneCpd5: return "日均低于 5 元"
            case .milestoneCpd2: return "日均低于 2 元"
            case .milestoneCpd1: return "日均低于 1 元"
            case .milestoneCpd05: return "日均低于 5 毛"
            case .milestonePaidBack: return "完全回本"
            case .updates: return "软件更新"
            case .updateCheckTitle: return "正在检查更新…"
            case .upToDate: return "已是最新版本"
            case .updateAvailable: return "发现新版本"
            case .downloadUpdate: return "下载更新"
            case .downloading: return "正在下载…"
            case .installNow: return "退出并安装"
            case .installFailed: return "安装失败"
            case .updateError: return "更新失败"
            case .retry: return "重试"
            case .close: return "关闭"
            case .currency: return "货币"
            case .languageAuto: return "跟随系统"
            case .languageTitle: return "语言"
            case .digestTitle: return "回本快报"
            case .celebrateTitle: return "值得庆祝的时刻"
            case .celebrateKeep: return "用得越久，每天越轻。"
            case .quip1: return "每一次打开，都是在赚回当初的决定。"
            case .quip2: return "时间是你最便宜的合伙人。"
            case .quip3: return "今天不用，它也在帮你回本——不，还是用用它吧。"
            case .quip4: return "冲动是魔鬼，折旧是天使。"
            case .quip5: return "好的购买，是用得越久越便宜。"
            case .quip6: return "别数钱了——好吧，再数一次。"
            case .curveDayLabel: return "第 {day} 天"
            case .updateAvailableBody: return "发现新版本 {version}（{size}），要现在下载吗？"
            case .updateReadyBody: return "新版本 {version} 已下载完成，退出并安装？"
            case .updateInstallFailedBody: return "上次更新安装失败（msiexec 错误 {code}）。当前版本不受影响，可稍后在「检查更新」重试，或到 GitHub Releases 手动下载安装包。"
            case .updateInstallNote: return "下载已完成并通过签名校验。用新版 tar.gz 覆盖应用目录即可完成更新。"
            case .updateOpenFolder: return "打开所在文件夹"
            case .digestBody: return "个人使用价值已超出购买成本 {earned}。"
            case .digestBodyBest: return "{name} 今天只要 {cost}"
            case .aboutMenu: return "关于 Payback"
            case .aboutContent: return "记录电子产品的购买价格，看着每日成本一天天降下去\n用得越久，越接近回本"
            case .aboutLicense: return "以 MIT 许可证授权发布"
            case .aboutWebsite: return "访问官网"
            case .aboutReportIssue: return "问题反馈"
            case .settingsTitle: return "设置"
            case .dataSyncSection: return "数据与同步"
            case .syncHowItWorks: return "把数据放进任意网盘文件夹（iCloud Drive、OneDrive、坚果云、Syncthing…），任一台设备录入，处处可见。"
            case .syncStatusOff: return "未开启同步"
            case .syncStatusOn: return "同步已开启"
            case .syncEnable: return "开启同步…"
            case .syncDisable: return "停止同步"
            case .syncDisableConfirmTitle: return "停止同步？"
            case .syncDisableConfirmBody: return "本机数据保留在本地，不再与其他设备合并。"
            case .syncFolderLabel: return "同步文件夹"
            case .syncChooseFolder: return "选择文件夹…"
            case .syncPickFolderTitle: return "选择用于同步的文件夹"
            case .syncDetectedTitle: return "检测到同步文件夹"
            case .syncDetectedBody: return "检测到 {folder}，用它来同步吗？"
            case .syncUseDetected: return "使用"
            case .syncMachinesLabel: return "参与同步的设备"
            case .syncMachineNameLabel: return "本机名称"
            case .syncLastMergeLabel: return "上次合并"
            case .syncIgnoredWarning: return "{count} 个文件无法读取，已跳过（常见于网盘冲突副本）。"
            case .syncOpenFolder: return "打开文件夹"
            case .syncEnableFailed: return "无法开启同步"
            case .currencyHint: return "新设备的默认货币"
            case .investmentEyebrow: return "设备投入 · {currency}"
            case .investmentCaption: return "让每一份投入，都用得值得。"
            case .dailyCostTotal: return "合计每日成本"
            case .devicesTracked: return "记录中的设备"
            case .mixedCurrencyNote: return "仅汇总当前默认货币。每日成本排序按币种分组，不换算汇率。"
            case .myDevices: return "我的设备"
            case .sortDate: return "最近购买"
            case .openSettingsHelp: return "打开设置"
            case .toggleAppearance: return "切换亮暗主题"
            case .preferencesBreadcrumb: return "偏好设置"
            case .addFirstDevice: return "添加第一台设备"
            case .emptyExample: return "一台 999 元的键盘，用满 1,000 天，每天成本约 1 元。"
            case .daysTogether: return "已陪伴 {days} 天"
            case .purchasedOn: return "购于"
            case .heroDailyLabel: return "现在的每日成本"
            case .heroDailyCaption: return "每多用一天，成本就再轻一点。"
            case .goalMetHeading: return "你的回本目标"
            case .goalRemainingHeading: return "距离回本目标"
            case .goalBasedOn: return "按每天 {amount} 的个人使用价值计算"
            case .goalExtra: return "已超出购买成本 {amount}"
            case .goalQuestion: return "什么价位，你觉得值得？"
            case .goalSetHint: return "设定每天愿意付的金额，看看何时达到自己的目标。"
            case .setDailyValue: return "设置每日价值"
            case .chartTitle: return "成本，一天比一天轻"
            case .chartSubtitle: return "{days} 天的变化"
            case .chartDayOne: return "购买当天 · {amount}"
            case .chartToday: return "今天 · {amount}"
            case .chartNote: return "每日成本 = 购买价格 ÷ 持有天数"
            case .chartA11y: return "每日成本随持有时间下降，当前为 {cost}"
            case .milestonesTitle: return "一路的小里程碑"
            case .milestoneReached: return "已达成"
            case .milestoneDaysToGo: return "还差 {days} 天"
            case .costMilestonesTitle: return "查看成本里程碑"
            case .costMilestoneBelow: return "日均低于 {amount} / 天"
            case .costMilestoneNotYet: return "未达成"
            case .methodTitle: return "怎样理解回本？"
            case .methodIntro1: return "这里的回本，是达到你心中“用得值得”的目标。"
            case .methodIntro2: return "它按你设定的每日价值累计，不代表真实收入或转售价值。"
            case .methodCalcTitle: return "计算方式"
            case .methodCalcDays: return "回本天数 = 购买价格 ÷ 每日价值，向上取整。持有天数从购买当天算起。"
            case .methodCalcReset: return "修改每日价值后，将按新标准重新计算全部持有时间。"
            case .notesTitle: return "设备备注"
            case .moveToDeleted: return "移到最近删除"
            case .keepDevice: return "保留设备"
            case .toastDeleted: return "设备已移到最近删除"
            case .undo: return "撤销"
            case .deviceRestored: return "已恢复设备"
            case .trashTitle: return "最近删除"
            case .trashIntro: return "恢复后会回到设备库，购买记录和每日价值保持不变。"
            case .trashEmpty: return "没有待恢复的设备。"
            case .restoreButton: return "恢复"
            case .trashRowHelp: return "{count} 台设备可恢复；不会自动清空。"
            case .trashView: return "查看与恢复"
            case .sectionLanguageAppearance: return "语言与外观"
            case .sectionDataRecovery: return "数据与恢复"
            case .languageRowHelp: return "切换全部界面与日期、金额格式，设备名称及备注保持原文。"
            case .appearanceRowLabel: return "外观"
            case .appearanceRowHelp: return "选择舒适的阅读方式。"
            case .appearanceSystem: return "跟随系统"
            case .appearanceLight: return "浅色"
            case .appearanceDark: return "深色"
            case .currencyNotConverted: return "用于新增与汇总；已有记录不换算。"
            case .backupExportRow: return "备份导出"
            case .backupExportHelp: return "导出设备、最近删除与偏好设置。"
            case .backupExportButton: return "导出 JSON"
            case .restoreRow: return "从备份恢复"
            case .restoreRowHelp: return "先校验文件并展示替换范围，确认后再恢复。"
            case .chooseBackupButton: return "选择备份"
            case .syncRowLabel: return "跨设备同步"
            case .backupCheckTitle: return "检查备份"
            case .backupCheckBody: return "正在读取并校验备份…"
            case .restoreReviewTitle: return "确认恢复备份"
            case .restoreReplacedLabel: return "当前设备将被替换"
            case .restoreImportedLabel: return "备份中的设备"
            case .restoreTrashLabel: return "可恢复的删除记录"
            case .restorePrefsNote: return "语言、外观与默认货币也会恢复。"
            case .restoreWarning: return "恢复会替换当前记录。建议先导出当前备份再继续。"
            case .restoreConfirm: return "确认恢复"
            case .backupFirst: return "先备份当前数据"
            case .backupInvalid: return "备份格式、版本或记录不合法，未更改当前数据。"
            case .backupRestored: return "备份已恢复"
            case .backupTooLarge: return "备份不能超过 5 MB，当前数据未改变。"
            case .deviceSaved: return "设备已保存"
            case .preferencesUpdated: return "偏好已更新"
            case .goalEnabledLabel: return "设置每天愿意付的金额"
            case .goalSectionTitle: return "你的回本目标"
            case .dailyValue: return "每日价值"
            case .dailyValueHelp: return "例如每天 2 元。累计使用价值达到购买价格时，视为回本。"
            case .notesOptional: return "添加备注（可选）"
            case .formNameRequired: return "设备名称 · 必填"
            case .formPriceRequired: return "购买价格 · 必填"
            case .formDateRequired: return "购买日期 · 必填"
            case .saveDeviceButton: return "保存设备"
            case .savingShort: return "正在保存…"
            case .retrySave: return "重试保存"
            case .companionSection: return "移动端伴随"
            case .companionEnable: return "允许移动端连接"
            case .companionEnableHelp: return "在本地网络开启伴随通道；手机与本机配对后可读取和编辑同一份数据。默认关闭。"
            case .companionStatusOn: return "伴随通道运行中"
            case .companionStatusOff: return "伴随通道已关闭"
            case .companionOpenWindow: return "打开配对窗口"
            case .companionWindowHint: return "配对窗口五分钟后关闭。"
            case .companionPromptTitle: return "手机配对请求"
            case .companionPromptBody: return "在手机上确认同一个六位码，两侧一致才批准。"
            case .companionApprove: return "批准"
            case .companionReject: return "拒绝"
            case .companionPairedLabel: return "已配对设备"
            case .companionRemove: return "移除"
            case .companionEmptyPaired: return "还没有已配对的移动设备。"
            case .companionFingerprint: return "服务器指纹"
            case .companionFailed: return "伴随通道出错"
            case .companionIdle: return "未连接桌面端"
            case .companionConnecting: return "正在安全连接…"
            case .companionConfirmCode: return "请确认配对码"
            case .companionConnected: return "已建立安全会话"
            case .companionSessionHeader: return "连接状态"
            case .companionDisconnect: return "断开"
            case .companionNearby: return "附近的桌面端"
            case .companionStopScan: return "停止扫描"
            case .companionScan: return "扫描桌面端"
            case .companionNoDevices: return "还没有发现桌面端。请确认桌面端已开启伴随通道，并处于同一网络。"
            case .companionWindowOpen: return "配对窗口已打开"
            case .companionWindowClosed: return "配对窗口未打开"
            case .companionWindowIDField: return "配对窗口 ID（桌面端设置里复制）"
            case .companionPair: return "配对"
            case .companionReconnect: return "重新连接"
            }
        }

        var en: String {
            switch self {
            case .startingBackend: return "Starting Racket engine…"
            case .backendReady: return "Racket CS ready"
            case .backendError: return "Backend error"
            case .configError: return "Configuration error"
            case .appName: return "Payback"
            case .tagline: return "The longer you keep it, the closer to your goal"
            case .totalSpent: return "Total spent"
            case .earnedBack: return "Earned back"
            case .deviceCount: return "devices"
            case .overallDaily: return "Overall daily"
            case .addDevice: return "Add Device"
            case .checkUpdatesMenu: return "Check for Updates…"
            case .helpMenu: return "Help"
            case .emptyTitle: return "Start with your first device"
            case .emptyHint: return "Record its price and purchase date, and watch its daily cost fall over time."
            case .sortBy: return "Sort"
            case .sortAdded: return "Date added"
            case .sortDailyCost: return "Daily cost"
            case .sortPayback: return "Payback progress"
            case .dailyCost: return "Daily cost"
            case .perDay: return "/day"
            case .heldFor: return "Held for"
            case .days: return "days"
            case .paidBack: return "Goal met"
            case .paybackProgress: return "Value goal progress"
            case .paybackEta: return "Break-even expected"
            case .earnedSoFar: return "Value gained beyond your price"
            case .stillToEarn: return "Remaining"
            case .willingPerDay: return "Willing to pay"
            case .notSet: return "Not set"
            case .milestones: return "Milestones"
            case .edit: return "Edit"
            case .delete: return "Delete"
            case .deleteConfirmTitle: return "Delete this device?"
            case .deleteConfirmText: return "The device moves to Recently deleted. Its record and goal can be restored."
            case .cancel: return "Cancel"
            case .save: return "Save"
            case .saving: return "Saving…"
            case .saveFailed: return "Save failed"
            case .genericError: return "Something went wrong"
            case .name: return "Name"
            case .icon: return "Icon"
            case .category: return "Category"
            case .price: return "Price"
            case .priceRequiredHint: return "Enter an amount greater than 0"
            case .purchaseDate: return "Purchase date"
            case .yearField: return "Year"
            case .monthField: return "Month"
            case .jumpToToday: return "Jump to Today"
            case .dateInvalidHint: return "Use year-month-day, e.g. 2026-10-15"
            case .notes: return "Notes"
            case .willingHint: return "Set what a day with this device is worth to you, and watch it pay itself back."
            case .willingLabel: return "Worth per day"
            case .categoryComputer: return "Computer"
            case .categoryPhone: return "Phone"
            case .categoryTablet: return "Tablet"
            case .categoryWatch: return "Watch"
            case .categoryAudio: return "Audio"
            case .categoryCamera: return "Camera"
            case .categoryGaming: return "Gaming"
            case .categoryAppliance: return "Appliance"
            case .categoryAccessory: return "Accessory"
            case .categoryOther: return "Other"
            case .milestoneDays100: return "100 days together"
            case .milestoneDays365: return "A full year"
            case .milestoneDays1000: return "1000-day friend"
            case .milestoneCpd10: return "Under 10/day"
            case .milestoneCpd5: return "Under 5/day"
            case .milestoneCpd2: return "Under 2/day"
            case .milestoneCpd1: return "Under 1/day"
            case .milestoneCpd05: return "Under 0.50/day"
            case .milestonePaidBack: return "Fully paid back"
            case .updates: return "Software Update"
            case .updateCheckTitle: return "Checking for updates…"
            case .upToDate: return "You're up to date"
            case .updateAvailable: return "Update available"
            case .downloadUpdate: return "Download Update"
            case .downloading: return "Downloading…"
            case .installNow: return "Quit and Install"
            case .installFailed: return "Install failed"
            case .updateError: return "Update failed"
            case .retry: return "Retry"
            case .close: return "Close"
            case .currency: return "Currency"
            case .languageAuto: return "Auto"
            case .languageTitle: return "Language"
            case .digestTitle: return "Payback digest"
            case .celebrateTitle: return "A moment worth celebrating"
            case .celebrateKeep: return "More days. Less per day."
            case .quip1: return "Every open is another step toward payback."
            case .quip2: return "Time is your cheapest business partner."
            case .quip3: return "It pays back even idle — but go use it anyway."
            case .quip4: return "Impulse is the devil; depreciation is the angel."
            case .quip5: return "A good purchase gets cheaper every day you use it."
            case .quip6: return "Stop counting the money — okay, one more look."
            case .curveDayLabel: return "day {day}"
            case .updateAvailableBody: return "Payback {version} ({size}) is available. Download it now?"
            case .updateReadyBody: return "Payback {version} is downloaded. Quit and install?"
            case .updateInstallFailedBody: return "The last update did not install (msiexec error {code}). This version is unaffected — retry from Check Updates later, or download the installer from GitHub Releases."
            case .updateInstallNote: return "The download is verified. Extract the new tar.gz over the app directory to finish the update."
            case .updateOpenFolder: return "Open folder"
            case .digestBody: return "Your personal value is now {earned} beyond what you paid."
            case .digestBodyBest: return "{name} costs just {cost} today"
            case .aboutMenu: return "About Payback"
            case .aboutContent: return "Log what your devices cost and watch the daily price drop\nThe longer you keep them, the more they pay back"
            case .aboutLicense: return "Released under the MIT License"
            case .aboutWebsite: return "Website"
            case .aboutReportIssue: return "Report an Issue"
            case .settingsTitle: return "Settings"
            case .dataSyncSection: return "Data & Sync"
            case .syncHowItWorks: return "Point Payback at any synced folder (iCloud Drive, OneDrive, Dropbox, Syncthing…). Enter a device once, see it everywhere."
            case .syncStatusOff: return "Sync is off"
            case .syncStatusOn: return "Sync is on"
            case .syncEnable: return "Turn On Sync…"
            case .syncDisable: return "Turn Off Sync"
            case .syncDisableConfirmTitle: return "Turn off sync?"
            case .syncDisableConfirmBody: return "Your data stays on this machine and no longer merges with your other devices."
            case .syncFolderLabel: return "Sync folder"
            case .syncChooseFolder: return "Choose Folder…"
            case .syncPickFolderTitle: return "Choose a Folder for Syncing"
            case .syncDetectedTitle: return "Sync Folder Found"
            case .syncDetectedBody: return "Found {folder}. Use it to sync your devices?"
            case .syncUseDetected: return "Use"
            case .syncMachinesLabel: return "Devices in This Sync"
            case .syncMachineNameLabel: return "This Machine's Name"
            case .syncLastMergeLabel: return "Last merge"
            case .syncIgnoredWarning: return "{count} file(s) could not be read and were skipped — often cloud conflict copies."
            case .syncOpenFolder: return "Open Folder"
            case .syncEnableFailed: return "Couldn't Enable Sync"
            case .currencyHint: return "Default currency for new devices"
            case .investmentEyebrow: return "Device investment · {currency}"
            case .investmentCaption: return "Make every purchase worth keeping."
            case .dailyCostTotal: return "Daily cost total"
            case .devicesTracked: return "Devices tracked"
            case .mixedCurrencyNote: return "Totals use the default currency. Daily costs are sorted within each currency, without conversion."
            case .myDevices: return "My devices"
            case .sortDate: return "Newest purchase"
            case .openSettingsHelp: return "Open settings"
            case .toggleAppearance: return "Toggle light and dark appearance"
            case .preferencesBreadcrumb: return "Preferences"
            case .addFirstDevice: return "Add your first device"
            case .emptyExample: return "A CNY 999 keyboard costs about CNY 1 a day after 1,000 days."
            case .daysTogether: return "{days} days together"
            case .purchasedOn: return "Purchased"
            case .heroDailyLabel: return "Your daily cost today"
            case .heroDailyCaption: return "Another day of use. A little less per day."
            case .goalMetHeading: return "Your personal value goal"
            case .goalRemainingHeading: return "Until your value goal"
            case .goalBasedOn: return "Based on your personal value of {amount} per day"
            case .goalExtra: return "Personal value beyond purchase cost: {amount}"
            case .goalQuestion: return "What feels worth it to you?"
            case .goalSetHint: return "Set what you would pay per day to see when your purchase feels worthwhile."
            case .setDailyValue: return "Set daily value"
            case .chartTitle: return "Less per day, every day"
            case .chartSubtitle: return "{days} days of ownership"
            case .chartDayOne: return "Day one · {amount}"
            case .chartToday: return "Today · {amount}"
            case .chartNote: return "Daily cost = purchase price ÷ days owned"
            case .chartA11y: return "Daily cost decreases with ownership time. Current cost: {cost}"
            case .milestonesTitle: return "Small milestones"
            case .milestoneReached: return "Reached"
            case .milestoneDaysToGo: return "{days} days to go"
            case .costMilestonesTitle: return "See daily cost milestones"
            case .costMilestoneBelow: return "Below {amount}/day"
            case .costMilestoneNotYet: return "Not yet"
            case .methodTitle: return "What does “goal met” mean?"
            case .methodIntro1: return "Your goal is reached when the accumulated personal value matches what you paid."
            case .methodIntro2: return "It uses the daily value you set. It is not income or resale value."
            case .methodCalcTitle: return "How it is calculated"
            case .methodCalcDays: return "Days to goal = purchase price ÷ daily value, rounded up. The purchase date counts as day one."
            case .methodCalcReset: return "Changing daily value recalculates the whole ownership period."
            case .notesTitle: return "Device notes"
            case .moveToDeleted: return "Move to deleted"
            case .keepDevice: return "Keep device"
            case .toastDeleted: return "Device moved to Recently deleted"
            case .undo: return "Undo"
            case .deviceRestored: return "Device restored"
            case .trashTitle: return "Recently deleted"
            case .trashIntro: return "Restored devices return to your library with their original purchase details and daily value."
            case .trashEmpty: return "No devices to restore."
            case .restoreButton: return "Restore"
            case .trashRowHelp: return "{count} devices can be restored. Nothing is purged automatically."
            case .trashView: return "View & restore"
            case .sectionLanguageAppearance: return "Language & appearance"
            case .sectionDataRecovery: return "Data & recovery"
            case .languageRowHelp: return "Updates the interface and formatting. Device names and notes stay as entered."
            case .appearanceRowLabel: return "Appearance"
            case .appearanceRowHelp: return "Choose what feels comfortable to read."
            case .appearanceSystem: return "System default"
            case .appearanceLight: return "Light"
            case .appearanceDark: return "Dark"
            case .currencyNotConverted: return "Used for new devices and totals. Existing amounts are not converted."
            case .backupExportRow: return "Export backup"
            case .backupExportHelp: return "Includes devices, deleted records, and preferences."
            case .backupExportButton: return "Export JSON"
            case .restoreRow: return "Restore backup"
            case .restoreRowHelp: return "Validate the file and review what will be replaced before restoring."
            case .chooseBackupButton: return "Choose backup"
            case .syncRowLabel: return "Cross-device sync"
            case .backupCheckTitle: return "Checking backup"
            case .backupCheckBody: return "Reading and validating the backup…"
            case .restoreReviewTitle: return "Review backup restore"
            case .restoreReplacedLabel: return "Current devices replaced"
            case .restoreImportedLabel: return "Devices in backup"
            case .restoreTrashLabel: return "Deleted records included"
            case .restorePrefsNote: return "Language, appearance, and default currency will also be restored."
            case .restoreWarning: return "Restoring replaces current records. Export your current data before proceeding."
            case .restoreConfirm: return "Restore backup"
            case .backupFirst: return "Back up current data"
            case .backupInvalid: return "The backup format, version, or records are invalid. Your data has not changed."
            case .backupRestored: return "Backup restored"
            case .backupTooLarge: return "Backups must be 5 MB or smaller. Your data has not changed."
            case .deviceSaved: return "Device saved"
            case .preferencesUpdated: return "Preferences updated"
            case .goalEnabledLabel: return "Set what you would pay per day"
            case .goalSectionTitle: return "Your personal value goal"
            case .dailyValue: return "Daily value"
            case .dailyValueHelp: return "For example, 2 units per day. Your goal is met when accumulated value reaches the purchase price."
            case .notesOptional: return "Notes (optional)"
            case .formNameRequired: return "Device name · required"
            case .formPriceRequired: return "Purchase price · required"
            case .formDateRequired: return "Purchase date · required"
            case .saveDeviceButton: return "Save device"
            case .savingShort: return "Saving…"
            case .retrySave: return "Retry save"
            case .companionSection: return "Mobile companion"
            case .companionEnable: return "Allow mobile connections"
            case .companionEnableHelp: return "Runs the companion channel on your local network. A paired phone reads and edits the same data. Off by default."
            case .companionStatusOn: return "Companion channel running"
            case .companionStatusOff: return "Companion channel off"
            case .companionOpenWindow: return "Open pairing window"
            case .companionWindowHint: return "The pairing window closes after five minutes."
            case .companionPromptTitle: return "Phone pairing request"
            case .companionPromptBody: return "Confirm the same six-digit code on the phone. Approve only if both screens match."
            case .companionApprove: return "Approve"
            case .companionReject: return "Reject"
            case .companionPairedLabel: return "Paired devices"
            case .companionRemove: return "Remove"
            case .companionEmptyPaired: return "No paired mobile devices yet."
            case .companionFingerprint: return "Server fingerprint"
            case .companionFailed: return "Companion channel error"
            case .companionIdle: return "Desktop not connected"
            case .companionConnecting: return "Connecting securely…"
            case .companionConfirmCode: return "Confirm the pairing code"
            case .companionConnected: return "Secure session established"
            case .companionSessionHeader: return "Connection"
            case .companionDisconnect: return "Disconnect"
            case .companionNearby: return "Nearby desktops"
            case .companionStopScan: return "Stop scanning"
            case .companionScan: return "Scan for desktops"
            case .companionNoDevices: return "No desktops found yet. Make sure the desktop companion channel is on and both devices share a network."
            case .companionWindowOpen: return "Pairing window open"
            case .companionWindowClosed: return "Pairing window closed"
            case .companionWindowIDField: return "Pairing window ID (copy from desktop settings)"
            case .companionPair: return "Pair"
            case .companionReconnect: return "Reconnect"
            }
        }
    }
}
