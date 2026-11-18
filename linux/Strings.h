// GENERATED from shared/strings/strings.json by scripts/gen-strings.js.
// Do not edit by hand: change strings.json and re-run the generator.
#pragma once

#include <string>

// UTF-8 narrow strings for the GTK host; the caller decides zh (in-app
// override, then the system language) and constructs Strings with it.
namespace payback::linux_strings {

struct Strings {
  bool zh;

  explicit Strings(bool chinese) : zh(chinese) {}

  std::string starting_backend() const { return zh ? "正在启动 Racket 引擎…" : "Starting Racket engine…"; }
  std::string backend_ready() const { return zh ? "Racket CS 就绪" : "Racket CS ready"; }
  std::string backend_error() const { return zh ? "后端错误" : "Backend error"; }
  std::string config_error() const { return zh ? "配置错误" : "Configuration error"; }
  std::string app_name() const { return zh ? "Payback 回本" : "Payback"; }
  std::string tagline() const { return zh ? "用得越久，越接近回本" : "The longer you keep it, the closer to your goal"; }
  std::string total_spent() const { return zh ? "累计投入" : "Total spent"; }
  std::string earned_back() const { return zh ? "已赚回" : "Earned back"; }
  std::string device_count() const { return zh ? "设备" : "devices"; }
  std::string overall_daily() const { return zh ? "整体日均" : "Overall daily"; }
  std::string add_device() const { return zh ? "添加设备" : "Add Device"; }
  std::string check_updates_menu() const { return zh ? "检查更新…" : "Check for Updates…"; }
  std::string help_menu() const { return zh ? "帮助" : "Help"; }
  std::string empty_title() const { return zh ? "从第一台设备开始" : "Start with your first device"; }
  std::string empty_hint() const { return zh ? "记下价格和购买日期，看看它的每日成本如何一点点降下来。" : "Record its price and purchase date, and watch its daily cost fall over time."; }
  std::string sort_by() const { return zh ? "排序" : "Sort"; }
  std::string sort_added() const { return zh ? "加入顺序" : "Date added"; }
  std::string sort_daily_cost() const { return zh ? "日均成本" : "Daily cost"; }
  std::string sort_payback() const { return zh ? "回本进度" : "Payback progress"; }
  std::string daily_cost() const { return zh ? "每日成本" : "Daily cost"; }
  std::string per_day() const { return zh ? "/天" : "/day"; }
  std::string held_for() const { return zh ? "已持有" : "Held for"; }
  std::string days() const { return zh ? "天" : "days"; }
  std::string paid_back() const { return zh ? "已回本" : "Goal met"; }
  std::string payback_progress() const { return zh ? "回本进度" : "Value goal progress"; }
  std::string payback_eta() const { return zh ? "预计回本" : "Break-even expected"; }
  std::string earned_so_far() const { return zh ? "按你的心理价位，已经多用出" : "Value gained beyond your price"; }
  std::string still_to_earn() const { return zh ? "还差" : "Remaining"; }
  std::string willing_per_day() const { return zh ? "每天愿意付" : "Willing to pay"; }
  std::string not_set() const { return zh ? "未设置" : "Not set"; }
  std::string milestones() const { return zh ? "里程碑" : "Milestones"; }
  std::string edit() const { return zh ? "编辑" : "Edit"; }
  std::string remove() const { return zh ? "删除" : "Delete"; }
  std::string delete_confirm_title() const { return zh ? "删除这台设备？" : "Delete this device?"; }
  std::string delete_confirm_text() const { return zh ? "设备将移到最近删除，记录与目标均可恢复。" : "The device moves to Recently deleted. Its record and goal can be restored."; }
  std::string cancel() const { return zh ? "取消" : "Cancel"; }
  std::string save() const { return zh ? "保存" : "Save"; }
  std::string saving() const { return zh ? "保存中…" : "Saving…"; }
  std::string save_failed() const { return zh ? "保存失败" : "Save failed"; }
  std::string generic_error() const { return zh ? "出了点问题" : "Something went wrong"; }
  std::string name() const { return zh ? "名称" : "Name"; }
  std::string icon() const { return zh ? "图标" : "Icon"; }
  std::string category() const { return zh ? "分类" : "Category"; }
  std::string price() const { return zh ? "购买价格" : "Price"; }
  std::string price_required_hint() const { return zh ? "请输入大于 0 的金额" : "Enter an amount greater than 0"; }
  std::string purchase_date() const { return zh ? "购买日期" : "Purchase date"; }
  std::string year_field() const { return zh ? "年" : "Year"; }
  std::string month_field() const { return zh ? "月" : "Month"; }
  std::string jump_to_today() const { return zh ? "回到今天" : "Jump to Today"; }
  std::string date_invalid_hint() const { return zh ? "按 年-月-日 填写，例如 2026-10-15" : "Use year-month-day, e.g. 2026-10-15"; }
  std::string notes() const { return zh ? "备注" : "Notes"; }
  std::string willing_hint() const { return zh ? "设置“每天愿意付多少钱”，就能看到回本进度。" : "Set what a day with this device is worth to you, and watch it pay itself back."; }
  std::string willing_label() const { return zh ? "心理价位（每天）" : "Worth per day"; }
  std::string category_computer() const { return zh ? "电脑" : "Computer"; }
  std::string category_phone() const { return zh ? "手机" : "Phone"; }
  std::string category_tablet() const { return zh ? "平板" : "Tablet"; }
  std::string category_watch() const { return zh ? "手表" : "Watch"; }
  std::string category_audio() const { return zh ? "音频" : "Audio"; }
  std::string category_camera() const { return zh ? "相机" : "Camera"; }
  std::string category_gaming() const { return zh ? "游戏" : "Gaming"; }
  std::string category_appliance() const { return zh ? "家电" : "Appliance"; }
  std::string category_accessory() const { return zh ? "配件" : "Accessory"; }
  std::string category_other() const { return zh ? "其他" : "Other"; }
  std::string milestone_days100() const { return zh ? "百日纪念" : "100 days together"; }
  std::string milestone_days365() const { return zh ? "陪伴一整年" : "A full year"; }
  std::string milestone_days1000() const { return zh ? "一千天老友" : "1000-day friend"; }
  std::string milestone_cpd10() const { return zh ? "日均低于 10 元" : "Under 10/day"; }
  std::string milestone_cpd5() const { return zh ? "日均低于 5 元" : "Under 5/day"; }
  std::string milestone_cpd2() const { return zh ? "日均低于 2 元" : "Under 2/day"; }
  std::string milestone_cpd1() const { return zh ? "日均低于 1 元" : "Under 1/day"; }
  std::string milestone_cpd05() const { return zh ? "日均低于 5 毛" : "Under 0.50/day"; }
  std::string milestone_paid_back() const { return zh ? "完全回本" : "Fully paid back"; }
  std::string updates() const { return zh ? "软件更新" : "Software Update"; }
  std::string update_check_title() const { return zh ? "正在检查更新…" : "Checking for updates…"; }
  std::string up_to_date() const { return zh ? "已是最新版本" : "You're up to date"; }
  std::string update_available() const { return zh ? "发现新版本" : "Update available"; }
  std::string download_update() const { return zh ? "下载更新" : "Download Update"; }
  std::string downloading() const { return zh ? "正在下载…" : "Downloading…"; }
  std::string install_now() const { return zh ? "退出并安装" : "Quit and Install"; }
  std::string install_failed() const { return zh ? "安装失败" : "Install failed"; }
  std::string update_error() const { return zh ? "更新失败" : "Update failed"; }
  std::string retry() const { return zh ? "重试" : "Retry"; }
  std::string close() const { return zh ? "关闭" : "Close"; }
  std::string currency() const { return zh ? "货币" : "Currency"; }
  std::string language_auto() const { return zh ? "跟随系统" : "Auto"; }
  std::string language_title() const { return zh ? "语言" : "Language"; }
  std::string digest_title() const { return zh ? "回本快报" : "Payback digest"; }
  std::string celebrate_title() const { return zh ? "值得庆祝的时刻" : "A moment worth celebrating"; }
  std::string celebrate_keep() const { return zh ? "用得越久，每天越轻。" : "More days. Less per day."; }
  std::string quip1() const { return zh ? "每一次打开，都是在赚回当初的决定。" : "Every open is another step toward payback."; }
  std::string quip2() const { return zh ? "时间是你最便宜的合伙人。" : "Time is your cheapest business partner."; }
  std::string quip3() const { return zh ? "今天不用，它也在帮你回本——不，还是用用它吧。" : "It pays back even idle — but go use it anyway."; }
  std::string quip4() const { return zh ? "冲动是魔鬼，折旧是天使。" : "Impulse is the devil; depreciation is the angel."; }
  std::string quip5() const { return zh ? "好的购买，是用得越久越便宜。" : "A good purchase gets cheaper every day you use it."; }
  std::string quip6() const { return zh ? "别数钱了——好吧，再数一次。" : "Stop counting the money — okay, one more look."; }
  std::string curve_day_label() const { return zh ? "第 {day} 天" : "day {day}"; }
  std::string update_available_body() const { return zh ? "发现新版本 {version}（{size}），要现在下载吗？" : "Payback {version} ({size}) is available. Download it now?"; }
  std::string update_ready_body() const { return zh ? "新版本 {version} 已下载完成，退出并安装？" : "Payback {version} is downloaded. Quit and install?"; }
  std::string update_install_failed_body() const { return zh ? "上次更新安装失败（msiexec 错误 {code}）。当前版本不受影响，可稍后在「检查更新」重试，或到 GitHub Releases 手动下载安装包。" : "The last update did not install (msiexec error {code}). This version is unaffected — retry from Check Updates later, or download the installer from GitHub Releases."; }
  std::string update_install_note() const { return zh ? "下载已完成并通过签名校验。用新版 tar.gz 覆盖应用目录即可完成更新。" : "The download is verified. Extract the new tar.gz over the app directory to finish the update."; }
  std::string update_open_folder() const { return zh ? "打开所在文件夹" : "Open folder"; }
  std::string digest_body() const { return zh ? "个人使用价值已超出购买成本 {earned}。" : "Your personal value is now {earned} beyond what you paid."; }
  std::string digest_body_best() const { return zh ? "{name} 今天只要 {cost}" : "{name} costs just {cost} today"; }
  std::string about_menu() const { return zh ? "关于 Payback" : "About Payback"; }
  std::string about_content() const { return zh ? "记录电子产品的购买价格，看着每日成本一天天降下去\n用得越久，越接近回本" : "Log what your devices cost and watch the daily price drop\nThe longer you keep them, the more they pay back"; }
  std::string about_license() const { return zh ? "以 MIT 许可证授权发布" : "Released under the MIT License"; }
  std::string about_website() const { return zh ? "访问官网" : "Website"; }
  std::string about_report_issue() const { return zh ? "问题反馈" : "Report an Issue"; }
  std::string settings_title() const { return zh ? "设置" : "Settings"; }
  std::string data_sync_section() const { return zh ? "数据与同步" : "Data & Sync"; }
  std::string sync_how_it_works() const { return zh ? "把数据放进任意网盘文件夹（iCloud Drive、OneDrive、坚果云、Syncthing…），任一台设备录入，处处可见。" : "Point Payback at any synced folder (iCloud Drive, OneDrive, Dropbox, Syncthing…). Enter a device once, see it everywhere."; }
  std::string sync_status_off() const { return zh ? "未开启同步" : "Sync is off"; }
  std::string sync_status_on() const { return zh ? "同步已开启" : "Sync is on"; }
  std::string sync_enable() const { return zh ? "开启同步…" : "Turn On Sync…"; }
  std::string sync_disable() const { return zh ? "停止同步" : "Turn Off Sync"; }
  std::string sync_disable_confirm_title() const { return zh ? "停止同步？" : "Turn off sync?"; }
  std::string sync_disable_confirm_body() const { return zh ? "本机数据保留在本地，不再与其他设备合并。" : "Your data stays on this machine and no longer merges with your other devices."; }
  std::string sync_folder_label() const { return zh ? "同步文件夹" : "Sync folder"; }
  std::string sync_choose_folder() const { return zh ? "选择文件夹…" : "Choose Folder…"; }
  std::string sync_pick_folder_title() const { return zh ? "选择用于同步的文件夹" : "Choose a Folder for Syncing"; }
  std::string sync_detected_title() const { return zh ? "检测到同步文件夹" : "Sync Folder Found"; }
  std::string sync_detected_body() const { return zh ? "检测到 {folder}，用它来同步吗？" : "Found {folder}. Use it to sync your devices?"; }
  std::string sync_use_detected() const { return zh ? "使用" : "Use"; }
  std::string sync_machines_label() const { return zh ? "参与同步的设备" : "Devices in This Sync"; }
  std::string sync_machine_name_label() const { return zh ? "本机名称" : "This Machine's Name"; }
  std::string sync_last_merge_label() const { return zh ? "上次合并" : "Last merge"; }
  std::string sync_ignored_warning() const { return zh ? "{count} 个文件无法读取，已跳过（常见于网盘冲突副本）。" : "{count} file(s) could not be read and were skipped — often cloud conflict copies."; }
  std::string sync_open_folder() const { return zh ? "打开文件夹" : "Open Folder"; }
  std::string sync_enable_failed() const { return zh ? "无法开启同步" : "Couldn't Enable Sync"; }
  std::string currency_hint() const { return zh ? "新设备的默认货币" : "Default currency for new devices"; }
  std::string investment_eyebrow() const { return zh ? "设备投入 · {currency}" : "Device investment · {currency}"; }
  std::string investment_caption() const { return zh ? "让每一份投入，都用得值得。" : "Make every purchase worth keeping."; }
  std::string daily_cost_total() const { return zh ? "合计每日成本" : "Daily cost total"; }
  std::string devices_tracked() const { return zh ? "记录中的设备" : "Devices tracked"; }
  std::string mixed_currency_note() const { return zh ? "仅汇总当前默认货币。每日成本排序按币种分组，不换算汇率。" : "Totals use the default currency. Daily costs are sorted within each currency, without conversion."; }
  std::string my_devices() const { return zh ? "我的设备" : "My devices"; }
  std::string sort_date() const { return zh ? "最近购买" : "Newest purchase"; }
  std::string open_settings_help() const { return zh ? "打开设置" : "Open settings"; }
  std::string toggle_appearance() const { return zh ? "切换亮暗主题" : "Toggle light and dark appearance"; }
  std::string preferences_breadcrumb() const { return zh ? "偏好设置" : "Preferences"; }
  std::string add_first_device() const { return zh ? "添加第一台设备" : "Add your first device"; }
  std::string empty_example() const { return zh ? "一台 999 元的键盘，用满 1,000 天，每天成本约 1 元。" : "A CNY 999 keyboard costs about CNY 1 a day after 1,000 days."; }
  std::string days_together() const { return zh ? "已陪伴 {days} 天" : "{days} days together"; }
  std::string purchased_on() const { return zh ? "购于" : "Purchased"; }
  std::string hero_daily_label() const { return zh ? "现在的每日成本" : "Your daily cost today"; }
  std::string hero_daily_caption() const { return zh ? "每多用一天，成本就再轻一点。" : "Another day of use. A little less per day."; }
  std::string goal_met_heading() const { return zh ? "你的回本目标" : "Your personal value goal"; }
  std::string goal_remaining_heading() const { return zh ? "距离回本目标" : "Until your value goal"; }
  std::string goal_based_on() const { return zh ? "按每天 {amount} 的个人使用价值计算" : "Based on your personal value of {amount} per day"; }
  std::string goal_extra() const { return zh ? "已超出购买成本 {amount}" : "Personal value beyond purchase cost: {amount}"; }
  std::string goal_question() const { return zh ? "什么价位，你觉得值得？" : "What feels worth it to you?"; }
  std::string goal_set_hint() const { return zh ? "设定每天愿意付的金额，看看何时达到自己的目标。" : "Set what you would pay per day to see when your purchase feels worthwhile."; }
  std::string set_daily_value() const { return zh ? "设置每日价值" : "Set daily value"; }
  std::string chart_title() const { return zh ? "成本，一天比一天轻" : "Less per day, every day"; }
  std::string chart_subtitle() const { return zh ? "{days} 天的变化" : "{days} days of ownership"; }
  std::string chart_day_one() const { return zh ? "购买当天 · {amount}" : "Day one · {amount}"; }
  std::string chart_today() const { return zh ? "今天 · {amount}" : "Today · {amount}"; }
  std::string chart_note() const { return zh ? "每日成本 = 购买价格 ÷ 持有天数" : "Daily cost = purchase price ÷ days owned"; }
  std::string chart_a11y() const { return zh ? "每日成本随持有时间下降，当前为 {cost}" : "Daily cost decreases with ownership time. Current cost: {cost}"; }
  std::string milestones_title() const { return zh ? "一路的小里程碑" : "Small milestones"; }
  std::string milestone_reached() const { return zh ? "已达成" : "Reached"; }
  std::string milestone_days_to_go() const { return zh ? "还差 {days} 天" : "{days} days to go"; }
  std::string cost_milestones_title() const { return zh ? "查看成本里程碑" : "See daily cost milestones"; }
  std::string cost_milestone_below() const { return zh ? "日均低于 {amount} / 天" : "Below {amount}/day"; }
  std::string cost_milestone_not_yet() const { return zh ? "未达成" : "Not yet"; }
  std::string method_title() const { return zh ? "怎样理解回本？" : "What does “goal met” mean?"; }
  std::string method_intro1() const { return zh ? "这里的回本，是达到你心中“用得值得”的目标。" : "Your goal is reached when the accumulated personal value matches what you paid."; }
  std::string method_intro2() const { return zh ? "它按你设定的每日价值累计，不代表真实收入或转售价值。" : "It uses the daily value you set. It is not income or resale value."; }
  std::string method_calc_title() const { return zh ? "计算方式" : "How it is calculated"; }
  std::string method_calc_days() const { return zh ? "回本天数 = 购买价格 ÷ 每日价值，向上取整。持有天数从购买当天算起。" : "Days to goal = purchase price ÷ daily value, rounded up. The purchase date counts as day one."; }
  std::string method_calc_reset() const { return zh ? "修改每日价值后，将按新标准重新计算全部持有时间。" : "Changing daily value recalculates the whole ownership period."; }
  std::string notes_title() const { return zh ? "设备备注" : "Device notes"; }
  std::string move_to_deleted() const { return zh ? "移到最近删除" : "Move to deleted"; }
  std::string keep_device() const { return zh ? "保留设备" : "Keep device"; }
  std::string toast_deleted() const { return zh ? "设备已移到最近删除" : "Device moved to Recently deleted"; }
  std::string undo() const { return zh ? "撤销" : "Undo"; }
  std::string device_restored() const { return zh ? "已恢复设备" : "Device restored"; }
  std::string trash_title() const { return zh ? "最近删除" : "Recently deleted"; }
  std::string trash_intro() const { return zh ? "恢复后会回到设备库，购买记录和每日价值保持不变。" : "Restored devices return to your library with their original purchase details and daily value."; }
  std::string trash_empty() const { return zh ? "没有待恢复的设备。" : "No devices to restore."; }
  std::string restore_button() const { return zh ? "恢复" : "Restore"; }
  std::string trash_row_help() const { return zh ? "{count} 台设备可恢复；不会自动清空。" : "{count} devices can be restored. Nothing is purged automatically."; }
  std::string trash_view() const { return zh ? "查看与恢复" : "View & restore"; }
  std::string section_language_appearance() const { return zh ? "语言与外观" : "Language & appearance"; }
  std::string section_data_recovery() const { return zh ? "数据与恢复" : "Data & recovery"; }
  std::string language_row_help() const { return zh ? "切换全部界面与日期、金额格式，设备名称及备注保持原文。" : "Updates the interface and formatting. Device names and notes stay as entered."; }
  std::string appearance_row_label() const { return zh ? "外观" : "Appearance"; }
  std::string appearance_row_help() const { return zh ? "选择舒适的阅读方式。" : "Choose what feels comfortable to read."; }
  std::string appearance_system() const { return zh ? "跟随系统" : "System default"; }
  std::string appearance_light() const { return zh ? "浅色" : "Light"; }
  std::string appearance_dark() const { return zh ? "深色" : "Dark"; }
  std::string currency_not_converted() const { return zh ? "用于新增与汇总；已有记录不换算。" : "Used for new devices and totals. Existing amounts are not converted."; }
  std::string backup_export_row() const { return zh ? "备份导出" : "Export backup"; }
  std::string backup_export_help() const { return zh ? "导出设备、最近删除与偏好设置。" : "Includes devices, deleted records, and preferences."; }
  std::string backup_export_button() const { return zh ? "导出 JSON" : "Export JSON"; }
  std::string restore_row() const { return zh ? "从备份恢复" : "Restore backup"; }
  std::string restore_row_help() const { return zh ? "先校验文件并展示替换范围，确认后再恢复。" : "Validate the file and review what will be replaced before restoring."; }
  std::string choose_backup_button() const { return zh ? "选择备份" : "Choose backup"; }
  std::string sync_row_label() const { return zh ? "跨设备同步" : "Cross-device sync"; }
  std::string backup_check_title() const { return zh ? "检查备份" : "Checking backup"; }
  std::string backup_check_body() const { return zh ? "正在读取并校验备份…" : "Reading and validating the backup…"; }
  std::string restore_review_title() const { return zh ? "确认恢复备份" : "Review backup restore"; }
  std::string restore_replaced_label() const { return zh ? "当前设备将被替换" : "Current devices replaced"; }
  std::string restore_imported_label() const { return zh ? "备份中的设备" : "Devices in backup"; }
  std::string restore_trash_label() const { return zh ? "可恢复的删除记录" : "Deleted records included"; }
  std::string restore_prefs_note() const { return zh ? "语言、外观与默认货币也会恢复。" : "Language, appearance, and default currency will also be restored."; }
  std::string restore_warning() const { return zh ? "恢复会替换当前记录。建议先导出当前备份再继续。" : "Restoring replaces current records. Export your current data before proceeding."; }
  std::string restore_confirm() const { return zh ? "确认恢复" : "Restore backup"; }
  std::string backup_first() const { return zh ? "先备份当前数据" : "Back up current data"; }
  std::string backup_invalid() const { return zh ? "备份格式、版本或记录不合法，未更改当前数据。" : "The backup format, version, or records are invalid. Your data has not changed."; }
  std::string backup_restored() const { return zh ? "备份已恢复" : "Backup restored"; }
  std::string backup_too_large() const { return zh ? "备份不能超过 5 MB，当前数据未改变。" : "Backups must be 5 MB or smaller. Your data has not changed."; }
  std::string device_saved() const { return zh ? "设备已保存" : "Device saved"; }
  std::string preferences_updated() const { return zh ? "偏好已更新" : "Preferences updated"; }
  std::string goal_enabled_label() const { return zh ? "设置每天愿意付的金额" : "Set what you would pay per day"; }
  std::string goal_section_title() const { return zh ? "你的回本目标" : "Your personal value goal"; }
  std::string daily_value() const { return zh ? "每日价值" : "Daily value"; }
  std::string daily_value_help() const { return zh ? "例如每天 2 元。累计使用价值达到购买价格时，视为回本。" : "For example, 2 units per day. Your goal is met when accumulated value reaches the purchase price."; }
  std::string notes_optional() const { return zh ? "添加备注（可选）" : "Notes (optional)"; }
  std::string form_name_required() const { return zh ? "设备名称 · 必填" : "Device name · required"; }
  std::string form_price_required() const { return zh ? "购买价格 · 必填" : "Purchase price · required"; }
  std::string form_date_required() const { return zh ? "购买日期 · 必填" : "Purchase date · required"; }
  std::string save_device_button() const { return zh ? "保存设备" : "Save device"; }
  std::string saving_short() const { return zh ? "正在保存…" : "Saving…"; }
  std::string retry_save() const { return zh ? "重试保存" : "Retry save"; }
  std::string companion_section() const { return zh ? "移动端伴随" : "Mobile companion"; }
  std::string companion_enable() const { return zh ? "允许移动端连接" : "Allow mobile connections"; }
  std::string companion_enable_help() const { return zh ? "在本地网络开启伴随通道；手机与本机配对后可读取和编辑同一份数据。默认关闭。" : "Runs the companion channel on your local network. A paired phone reads and edits the same data. Off by default."; }
  std::string companion_status_on() const { return zh ? "伴随通道运行中" : "Companion channel running"; }
  std::string companion_status_off() const { return zh ? "伴随通道已关闭" : "Companion channel off"; }
  std::string companion_open_window() const { return zh ? "打开配对窗口" : "Open pairing window"; }
  std::string companion_window_hint() const { return zh ? "配对窗口五分钟后关闭。" : "The pairing window closes after five minutes."; }
  std::string companion_prompt_title() const { return zh ? "手机配对请求" : "Phone pairing request"; }
  std::string companion_prompt_body() const { return zh ? "在手机上确认同一个六位码，两侧一致才批准。" : "Confirm the same six-digit code on the phone. Approve only if both screens match."; }
  std::string companion_approve() const { return zh ? "批准" : "Approve"; }
  std::string companion_reject() const { return zh ? "拒绝" : "Reject"; }
  std::string companion_paired_label() const { return zh ? "已配对设备" : "Paired devices"; }
  std::string companion_remove() const { return zh ? "移除" : "Remove"; }
  std::string companion_empty_paired() const { return zh ? "还没有已配对的移动设备。" : "No paired mobile devices yet."; }
  std::string companion_fingerprint() const { return zh ? "服务器指纹" : "Server fingerprint"; }
  std::string companion_failed() const { return zh ? "伴随通道出错" : "Companion channel error"; }
  std::string companion_idle() const { return zh ? "未连接桌面端" : "Desktop not connected"; }
  std::string companion_connecting() const { return zh ? "正在安全连接…" : "Connecting securely…"; }
  std::string companion_confirm_code() const { return zh ? "请确认配对码" : "Confirm the pairing code"; }
  std::string companion_connected() const { return zh ? "已建立安全会话" : "Secure session established"; }
  std::string companion_session_header() const { return zh ? "连接状态" : "Connection"; }
  std::string companion_disconnect() const { return zh ? "断开" : "Disconnect"; }
  std::string companion_nearby() const { return zh ? "附近的桌面端" : "Nearby desktops"; }
  std::string companion_stop_scan() const { return zh ? "停止扫描" : "Stop scanning"; }
  std::string companion_scan() const { return zh ? "扫描桌面端" : "Scan for desktops"; }
  std::string companion_no_devices() const { return zh ? "还没有发现桌面端。请确认桌面端已开启伴随通道，并处于同一网络。" : "No desktops found yet. Make sure the desktop companion channel is on and both devices share a network."; }
  std::string companion_window_open() const { return zh ? "配对窗口已打开" : "Pairing window open"; }
  std::string companion_window_closed() const { return zh ? "配对窗口未打开" : "Pairing window closed"; }
  std::string companion_window_i_d_field() const { return zh ? "配对窗口 ID（桌面端设置里复制）" : "Pairing window ID (copy from desktop settings)"; }
  std::string companion_pair() const { return zh ? "配对" : "Pair"; }
  std::string companion_reconnect() const { return zh ? "重新连接" : "Reconnect"; }
  std::string backup_export_done() const { return zh ? "备份已导出" : "Backup exported"; }
};

}  // namespace payback::linux_strings
