// GENERATED from shared/strings/strings.json by scripts/gen-strings.js.
// Do not edit by hand: change strings.json and re-run the generator.
#pragma once

#include <windows.h>
#include <string>

namespace payback::strings {

inline bool chinese_ui() {
  // WinAppSDK's cppwinrt projection does not carry Windows.System.Profile;
  // the plain Win32 language query covers zh-Hans and zh-Hant alike.
  return PRIMARYLANGID(::GetUserDefaultUILanguage()) == LANG_CHINESE;
}

// zh is the primary audience; English is selected automatically for
// non-Chinese systems.
struct Strings {
  bool zh;

  explicit Strings(bool chinese) : zh(chinese) {}

  std::wstring starting_backend() const { return zh ? L"正在启动 Racket 引擎…" : L"Starting Racket engine…"; }
  std::wstring backend_ready() const { return zh ? L"Racket CS 就绪" : L"Racket CS ready"; }
  std::wstring backend_error() const { return zh ? L"后端错误" : L"Backend error"; }
  std::wstring config_error() const { return zh ? L"配置错误" : L"Configuration error"; }
  std::wstring app_name() const { return zh ? L"Payback 回本" : L"Payback"; }
  std::wstring tagline() const { return zh ? L"用得越久，越接近回本" : L"The longer you keep it, the closer to your goal"; }
  std::wstring total_spent() const { return zh ? L"累计投入" : L"Total spent"; }
  std::wstring earned_back() const { return zh ? L"已赚回" : L"Earned back"; }
  std::wstring device_count() const { return zh ? L"设备" : L"devices"; }
  std::wstring overall_daily() const { return zh ? L"整体日均" : L"Overall daily"; }
  std::wstring add_device() const { return zh ? L"添加设备" : L"Add Device"; }
  std::wstring check_updates_menu() const { return zh ? L"检查更新…" : L"Check for Updates…"; }
  std::wstring help_menu() const { return zh ? L"帮助" : L"Help"; }
  std::wstring empty_title() const { return zh ? L"从第一台设备开始" : L"Start with your first device"; }
  std::wstring empty_hint() const { return zh ? L"记下价格和购买日期，看看它的每日成本如何一点点降下来。" : L"Record its price and purchase date, and watch its daily cost fall over time."; }
  std::wstring sort_by() const { return zh ? L"排序" : L"Sort"; }
  std::wstring sort_added() const { return zh ? L"加入顺序" : L"Date added"; }
  std::wstring sort_daily_cost() const { return zh ? L"日均成本" : L"Daily cost"; }
  std::wstring sort_payback() const { return zh ? L"回本进度" : L"Payback progress"; }
  std::wstring daily_cost() const { return zh ? L"每日成本" : L"Daily cost"; }
  std::wstring per_day() const { return zh ? L"/天" : L"/day"; }
  std::wstring held_for() const { return zh ? L"已持有" : L"Held for"; }
  std::wstring days() const { return zh ? L"天" : L"days"; }
  std::wstring paid_back() const { return zh ? L"已回本" : L"Goal met"; }
  std::wstring payback_progress() const { return zh ? L"回本进度" : L"Value goal progress"; }
  std::wstring payback_eta() const { return zh ? L"预计回本" : L"Break-even expected"; }
  std::wstring earned_so_far() const { return zh ? L"按你的心理价位，已经多用出" : L"Value gained beyond your price"; }
  std::wstring still_to_earn() const { return zh ? L"还差" : L"Remaining"; }
  std::wstring willing_per_day() const { return zh ? L"每天愿意付" : L"Willing to pay"; }
  std::wstring not_set() const { return zh ? L"未设置" : L"Not set"; }
  std::wstring milestones() const { return zh ? L"里程碑" : L"Milestones"; }
  std::wstring edit() const { return zh ? L"编辑" : L"Edit"; }
  std::wstring remove() const { return zh ? L"删除" : L"Delete"; }
  std::wstring delete_confirm_title() const { return zh ? L"删除这台设备？" : L"Delete this device?"; }
  std::wstring delete_confirm_text() const { return zh ? L"设备将移到最近删除，记录与目标均可恢复。" : L"The device moves to Recently deleted. Its record and goal can be restored."; }
  std::wstring cancel() const { return zh ? L"取消" : L"Cancel"; }
  std::wstring save() const { return zh ? L"保存" : L"Save"; }
  std::wstring saving() const { return zh ? L"保存中…" : L"Saving…"; }
  std::wstring save_failed() const { return zh ? L"保存失败" : L"Save failed"; }
  std::wstring generic_error() const { return zh ? L"出了点问题" : L"Something went wrong"; }
  std::wstring name() const { return zh ? L"名称" : L"Name"; }
  std::wstring icon() const { return zh ? L"图标" : L"Icon"; }
  std::wstring category() const { return zh ? L"分类" : L"Category"; }
  std::wstring price() const { return zh ? L"购买价格" : L"Price"; }
  std::wstring price_required_hint() const { return zh ? L"请输入大于 0 的金额" : L"Enter an amount greater than 0"; }
  std::wstring purchase_date() const { return zh ? L"购买日期" : L"Purchase date"; }
  std::wstring year_field() const { return zh ? L"年" : L"Year"; }
  std::wstring month_field() const { return zh ? L"月" : L"Month"; }
  std::wstring jump_to_today() const { return zh ? L"回到今天" : L"Jump to Today"; }
  std::wstring date_invalid_hint() const { return zh ? L"按 年-月-日 填写，例如 2026-10-15" : L"Use year-month-day, e.g. 2026-10-15"; }
  std::wstring notes() const { return zh ? L"备注" : L"Notes"; }
  std::wstring willing_hint() const { return zh ? L"设置“每天愿意付多少钱”，就能看到回本进度。" : L"Set what a day with this device is worth to you, and watch it pay itself back."; }
  std::wstring willing_label() const { return zh ? L"心理价位（每天）" : L"Worth per day"; }
  std::wstring category_computer() const { return zh ? L"电脑" : L"Computer"; }
  std::wstring category_phone() const { return zh ? L"手机" : L"Phone"; }
  std::wstring category_tablet() const { return zh ? L"平板" : L"Tablet"; }
  std::wstring category_watch() const { return zh ? L"手表" : L"Watch"; }
  std::wstring category_audio() const { return zh ? L"音频" : L"Audio"; }
  std::wstring category_camera() const { return zh ? L"相机" : L"Camera"; }
  std::wstring category_gaming() const { return zh ? L"游戏" : L"Gaming"; }
  std::wstring category_appliance() const { return zh ? L"家电" : L"Appliance"; }
  std::wstring category_accessory() const { return zh ? L"配件" : L"Accessory"; }
  std::wstring category_other() const { return zh ? L"其他" : L"Other"; }
  std::wstring milestone_days100() const { return zh ? L"百日纪念" : L"100 days together"; }
  std::wstring milestone_days365() const { return zh ? L"陪伴一整年" : L"A full year"; }
  std::wstring milestone_days1000() const { return zh ? L"一千天老友" : L"1000-day friend"; }
  std::wstring milestone_cpd10() const { return zh ? L"日均低于 10 元" : L"Under 10/day"; }
  std::wstring milestone_cpd5() const { return zh ? L"日均低于 5 元" : L"Under 5/day"; }
  std::wstring milestone_cpd2() const { return zh ? L"日均低于 2 元" : L"Under 2/day"; }
  std::wstring milestone_cpd1() const { return zh ? L"日均低于 1 元" : L"Under 1/day"; }
  std::wstring milestone_cpd05() const { return zh ? L"日均低于 5 毛" : L"Under 0.50/day"; }
  std::wstring milestone_paid_back() const { return zh ? L"完全回本" : L"Fully paid back"; }
  std::wstring updates() const { return zh ? L"软件更新" : L"Software Update"; }
  std::wstring update_check_title() const { return zh ? L"正在检查更新…" : L"Checking for updates…"; }
  std::wstring up_to_date() const { return zh ? L"已是最新版本" : L"You're up to date"; }
  std::wstring update_available() const { return zh ? L"发现新版本" : L"Update available"; }
  std::wstring download_update() const { return zh ? L"下载更新" : L"Download Update"; }
  std::wstring downloading() const { return zh ? L"正在下载…" : L"Downloading…"; }
  std::wstring install_now() const { return zh ? L"退出并安装" : L"Quit and Install"; }
  std::wstring install_failed() const { return zh ? L"安装失败" : L"Install failed"; }
  std::wstring update_error() const { return zh ? L"更新失败" : L"Update failed"; }
  std::wstring retry() const { return zh ? L"重试" : L"Retry"; }
  std::wstring close() const { return zh ? L"关闭" : L"Close"; }
  std::wstring currency() const { return zh ? L"货币" : L"Currency"; }
  std::wstring language_auto() const { return zh ? L"跟随系统" : L"Auto"; }
  std::wstring language_title() const { return zh ? L"语言" : L"Language"; }
  std::wstring digest_title() const { return zh ? L"回本快报" : L"Payback digest"; }
  std::wstring celebrate_title() const { return zh ? L"值得庆祝的时刻" : L"A moment worth celebrating"; }
  std::wstring celebrate_keep() const { return zh ? L"用得越久，每天越轻。" : L"More days. Less per day."; }
  std::wstring quip1() const { return zh ? L"每一次打开，都是在赚回当初的决定。" : L"Every open is another step toward payback."; }
  std::wstring quip2() const { return zh ? L"时间是你最便宜的合伙人。" : L"Time is your cheapest business partner."; }
  std::wstring quip3() const { return zh ? L"今天不用，它也在帮你回本——不，还是用用它吧。" : L"It pays back even idle — but go use it anyway."; }
  std::wstring quip4() const { return zh ? L"冲动是魔鬼，折旧是天使。" : L"Impulse is the devil; depreciation is the angel."; }
  std::wstring quip5() const { return zh ? L"好的购买，是用得越久越便宜。" : L"A good purchase gets cheaper every day you use it."; }
  std::wstring quip6() const { return zh ? L"别数钱了——好吧，再数一次。" : L"Stop counting the money — okay, one more look."; }
  std::wstring curve_day_label() const { return zh ? L"第 {day} 天" : L"day {day}"; }
  std::wstring update_available_body() const { return zh ? L"发现新版本 {version}（{size}），要现在下载吗？" : L"Payback {version} ({size}) is available. Download it now?"; }
  std::wstring update_ready_body() const { return zh ? L"新版本 {version} 已下载完成，退出并安装？" : L"Payback {version} is downloaded. Quit and install?"; }
  std::wstring update_install_failed_body() const { return zh ? L"上次更新安装失败（msiexec 错误 {code}）。当前版本不受影响，可稍后在「检查更新」重试，或到 GitHub Releases 手动下载安装包。" : L"The last update did not install (msiexec error {code}). This version is unaffected — retry from Check Updates later, or download the installer from GitHub Releases."; }
  std::wstring update_install_note() const { return zh ? L"下载已完成并通过签名校验。用新版 tar.gz 覆盖应用目录即可完成更新。" : L"The download is verified. Extract the new tar.gz over the app directory to finish the update."; }
  std::wstring update_open_folder() const { return zh ? L"打开所在文件夹" : L"Open folder"; }
  std::wstring digest_body() const { return zh ? L"个人使用价值已超出购买成本 {earned}。" : L"Your personal value is now {earned} beyond what you paid."; }
  std::wstring digest_body_best() const { return zh ? L"{name} 今天只要 {cost}" : L"{name} costs just {cost} today"; }
  std::wstring about_menu() const { return zh ? L"关于 Payback" : L"About Payback"; }
  std::wstring about_content() const { return zh ? L"记录电子产品的购买价格，看着每日成本一天天降下去\n用得越久，越接近回本" : L"Log what your devices cost and watch the daily price drop\nThe longer you keep them, the more they pay back"; }
  std::wstring about_license() const { return zh ? L"以 MIT 许可证授权发布" : L"Released under the MIT License"; }
  std::wstring about_website() const { return zh ? L"访问官网" : L"Website"; }
  std::wstring about_report_issue() const { return zh ? L"问题反馈" : L"Report an Issue"; }
  std::wstring settings_title() const { return zh ? L"设置" : L"Settings"; }
  std::wstring data_sync_section() const { return zh ? L"数据与同步" : L"Data & Sync"; }
  std::wstring sync_how_it_works() const { return zh ? L"把数据放进任意网盘文件夹（iCloud Drive、OneDrive、坚果云、Syncthing…），任一台设备录入，处处可见。" : L"Point Payback at any synced folder (iCloud Drive, OneDrive, Dropbox, Syncthing…). Enter a device once, see it everywhere."; }
  std::wstring sync_status_off() const { return zh ? L"未开启同步" : L"Sync is off"; }
  std::wstring sync_status_on() const { return zh ? L"同步已开启" : L"Sync is on"; }
  std::wstring sync_enable() const { return zh ? L"开启同步…" : L"Turn On Sync…"; }
  std::wstring sync_disable() const { return zh ? L"停止同步" : L"Turn Off Sync"; }
  std::wstring sync_disable_confirm_title() const { return zh ? L"停止同步？" : L"Turn off sync?"; }
  std::wstring sync_disable_confirm_body() const { return zh ? L"本机数据保留在本地，不再与其他设备合并。" : L"Your data stays on this machine and no longer merges with your other devices."; }
  std::wstring sync_folder_label() const { return zh ? L"同步文件夹" : L"Sync folder"; }
  std::wstring sync_choose_folder() const { return zh ? L"选择文件夹…" : L"Choose Folder…"; }
  std::wstring sync_pick_folder_title() const { return zh ? L"选择用于同步的文件夹" : L"Choose a Folder for Syncing"; }
  std::wstring sync_detected_title() const { return zh ? L"检测到同步文件夹" : L"Sync Folder Found"; }
  std::wstring sync_detected_body() const { return zh ? L"检测到 {folder}，用它来同步吗？" : L"Found {folder}. Use it to sync your devices?"; }
  std::wstring sync_use_detected() const { return zh ? L"使用" : L"Use"; }
  std::wstring sync_machines_label() const { return zh ? L"参与同步的设备" : L"Devices in This Sync"; }
  std::wstring sync_machine_name_label() const { return zh ? L"本机名称" : L"This Machine's Name"; }
  std::wstring sync_last_merge_label() const { return zh ? L"上次合并" : L"Last merge"; }
  std::wstring sync_ignored_warning() const { return zh ? L"{count} 个文件无法读取，已跳过（常见于网盘冲突副本）。" : L"{count} file(s) could not be read and were skipped — often cloud conflict copies."; }
  std::wstring sync_open_folder() const { return zh ? L"打开文件夹" : L"Open Folder"; }
  std::wstring sync_enable_failed() const { return zh ? L"无法开启同步" : L"Couldn't Enable Sync"; }
  std::wstring currency_hint() const { return zh ? L"新设备的默认货币" : L"Default currency for new devices"; }
  std::wstring investment_eyebrow() const { return zh ? L"设备投入 · {currency}" : L"Device investment · {currency}"; }
  std::wstring investment_caption() const { return zh ? L"让每一份投入，都用得值得。" : L"Make every purchase worth keeping."; }
  std::wstring daily_cost_total() const { return zh ? L"合计每日成本" : L"Daily cost total"; }
  std::wstring devices_tracked() const { return zh ? L"记录中的设备" : L"Devices tracked"; }
  std::wstring mixed_currency_note() const { return zh ? L"仅汇总当前默认货币。每日成本排序按币种分组，不换算汇率。" : L"Totals use the default currency. Daily costs are sorted within each currency, without conversion."; }
  std::wstring my_devices() const { return zh ? L"我的设备" : L"My devices"; }
  std::wstring sort_date() const { return zh ? L"最近购买" : L"Newest purchase"; }
  std::wstring open_settings_help() const { return zh ? L"打开设置" : L"Open settings"; }
  std::wstring toggle_appearance() const { return zh ? L"切换亮暗主题" : L"Toggle light and dark appearance"; }
  std::wstring preferences_breadcrumb() const { return zh ? L"偏好设置" : L"Preferences"; }
  std::wstring add_first_device() const { return zh ? L"添加第一台设备" : L"Add your first device"; }
  std::wstring empty_example() const { return zh ? L"一台 999 元的键盘，用满 1,000 天，每天成本约 1 元。" : L"A CNY 999 keyboard costs about CNY 1 a day after 1,000 days."; }
  std::wstring days_together() const { return zh ? L"已陪伴 {days} 天" : L"{days} days together"; }
  std::wstring purchased_on() const { return zh ? L"购于" : L"Purchased"; }
  std::wstring hero_daily_label() const { return zh ? L"现在的每日成本" : L"Your daily cost today"; }
  std::wstring hero_daily_caption() const { return zh ? L"每多用一天，成本就再轻一点。" : L"Another day of use. A little less per day."; }
  std::wstring goal_met_heading() const { return zh ? L"你的回本目标" : L"Your personal value goal"; }
  std::wstring goal_remaining_heading() const { return zh ? L"距离回本目标" : L"Until your value goal"; }
  std::wstring goal_based_on() const { return zh ? L"按每天 {amount} 的个人使用价值计算" : L"Based on your personal value of {amount} per day"; }
  std::wstring goal_extra() const { return zh ? L"已超出购买成本 {amount}" : L"Personal value beyond purchase cost: {amount}"; }
  std::wstring goal_question() const { return zh ? L"什么价位，你觉得值得？" : L"What feels worth it to you?"; }
  std::wstring goal_set_hint() const { return zh ? L"设定每天愿意付的金额，看看何时达到自己的目标。" : L"Set what you would pay per day to see when your purchase feels worthwhile."; }
  std::wstring set_daily_value() const { return zh ? L"设置每日价值" : L"Set daily value"; }
  std::wstring chart_title() const { return zh ? L"成本，一天比一天轻" : L"Less per day, every day"; }
  std::wstring chart_subtitle() const { return zh ? L"{days} 天的变化" : L"{days} days of ownership"; }
  std::wstring chart_day_one() const { return zh ? L"购买当天 · {amount}" : L"Day one · {amount}"; }
  std::wstring chart_today() const { return zh ? L"今天 · {amount}" : L"Today · {amount}"; }
  std::wstring chart_note() const { return zh ? L"每日成本 = 购买价格 ÷ 持有天数" : L"Daily cost = purchase price ÷ days owned"; }
  std::wstring chart_a11y() const { return zh ? L"每日成本随持有时间下降，当前为 {cost}" : L"Daily cost decreases with ownership time. Current cost: {cost}"; }
  std::wstring milestones_title() const { return zh ? L"一路的小里程碑" : L"Small milestones"; }
  std::wstring milestone_reached() const { return zh ? L"已达成" : L"Reached"; }
  std::wstring milestone_days_to_go() const { return zh ? L"还差 {days} 天" : L"{days} days to go"; }
  std::wstring cost_milestones_title() const { return zh ? L"查看成本里程碑" : L"See daily cost milestones"; }
  std::wstring cost_milestone_below() const { return zh ? L"日均低于 {amount} / 天" : L"Below {amount}/day"; }
  std::wstring cost_milestone_not_yet() const { return zh ? L"未达成" : L"Not yet"; }
  std::wstring method_title() const { return zh ? L"怎样理解回本？" : L"What does “goal met” mean?"; }
  std::wstring method_intro1() const { return zh ? L"这里的回本，是达到你心中“用得值得”的目标。" : L"Your goal is reached when the accumulated personal value matches what you paid."; }
  std::wstring method_intro2() const { return zh ? L"它按你设定的每日价值累计，不代表真实收入或转售价值。" : L"It uses the daily value you set. It is not income or resale value."; }
  std::wstring method_calc_title() const { return zh ? L"计算方式" : L"How it is calculated"; }
  std::wstring method_calc_days() const { return zh ? L"回本天数 = 购买价格 ÷ 每日价值，向上取整。持有天数从购买当天算起。" : L"Days to goal = purchase price ÷ daily value, rounded up. The purchase date counts as day one."; }
  std::wstring method_calc_reset() const { return zh ? L"修改每日价值后，将按新标准重新计算全部持有时间。" : L"Changing daily value recalculates the whole ownership period."; }
  std::wstring notes_title() const { return zh ? L"设备备注" : L"Device notes"; }
  std::wstring move_to_deleted() const { return zh ? L"移到最近删除" : L"Move to deleted"; }
  std::wstring keep_device() const { return zh ? L"保留设备" : L"Keep device"; }
  std::wstring toast_deleted() const { return zh ? L"设备已移到最近删除" : L"Device moved to Recently deleted"; }
  std::wstring undo() const { return zh ? L"撤销" : L"Undo"; }
  std::wstring device_restored() const { return zh ? L"已恢复设备" : L"Device restored"; }
  std::wstring trash_title() const { return zh ? L"最近删除" : L"Recently deleted"; }
  std::wstring trash_intro() const { return zh ? L"恢复后会回到设备库，购买记录和每日价值保持不变。" : L"Restored devices return to your library with their original purchase details and daily value."; }
  std::wstring trash_empty() const { return zh ? L"没有待恢复的设备。" : L"No devices to restore."; }
  std::wstring restore_button() const { return zh ? L"恢复" : L"Restore"; }
  std::wstring trash_row_help() const { return zh ? L"{count} 台设备可恢复；不会自动清空。" : L"{count} devices can be restored. Nothing is purged automatically."; }
  std::wstring trash_view() const { return zh ? L"查看与恢复" : L"View & restore"; }
  std::wstring section_language_appearance() const { return zh ? L"语言与外观" : L"Language & appearance"; }
  std::wstring section_data_recovery() const { return zh ? L"数据与恢复" : L"Data & recovery"; }
  std::wstring language_row_help() const { return zh ? L"切换全部界面与日期、金额格式，设备名称及备注保持原文。" : L"Updates the interface and formatting. Device names and notes stay as entered."; }
  std::wstring appearance_row_label() const { return zh ? L"外观" : L"Appearance"; }
  std::wstring appearance_row_help() const { return zh ? L"选择舒适的阅读方式。" : L"Choose what feels comfortable to read."; }
  std::wstring appearance_system() const { return zh ? L"跟随系统" : L"System default"; }
  std::wstring appearance_light() const { return zh ? L"浅色" : L"Light"; }
  std::wstring appearance_dark() const { return zh ? L"深色" : L"Dark"; }
  std::wstring currency_not_converted() const { return zh ? L"用于新增与汇总；已有记录不换算。" : L"Used for new devices and totals. Existing amounts are not converted."; }
  std::wstring backup_export_row() const { return zh ? L"备份导出" : L"Export backup"; }
  std::wstring backup_export_help() const { return zh ? L"导出设备、最近删除与偏好设置。" : L"Includes devices, deleted records, and preferences."; }
  std::wstring backup_export_button() const { return zh ? L"导出 JSON" : L"Export JSON"; }
  std::wstring restore_row() const { return zh ? L"从备份恢复" : L"Restore backup"; }
  std::wstring restore_row_help() const { return zh ? L"先校验文件并展示替换范围，确认后再恢复。" : L"Validate the file and review what will be replaced before restoring."; }
  std::wstring choose_backup_button() const { return zh ? L"选择备份" : L"Choose backup"; }
  std::wstring sync_row_label() const { return zh ? L"跨设备同步" : L"Cross-device sync"; }
  std::wstring backup_check_title() const { return zh ? L"检查备份" : L"Checking backup"; }
  std::wstring backup_check_body() const { return zh ? L"正在读取并校验备份…" : L"Reading and validating the backup…"; }
  std::wstring restore_review_title() const { return zh ? L"确认恢复备份" : L"Review backup restore"; }
  std::wstring restore_replaced_label() const { return zh ? L"当前设备将被替换" : L"Current devices replaced"; }
  std::wstring restore_imported_label() const { return zh ? L"备份中的设备" : L"Devices in backup"; }
  std::wstring restore_trash_label() const { return zh ? L"可恢复的删除记录" : L"Deleted records included"; }
  std::wstring restore_prefs_note() const { return zh ? L"语言、外观与默认货币也会恢复。" : L"Language, appearance, and default currency will also be restored."; }
  std::wstring restore_warning() const { return zh ? L"恢复会替换当前记录。建议先导出当前备份再继续。" : L"Restoring replaces current records. Export your current data before proceeding."; }
  std::wstring restore_confirm() const { return zh ? L"确认恢复" : L"Restore backup"; }
  std::wstring backup_first() const { return zh ? L"先备份当前数据" : L"Back up current data"; }
  std::wstring backup_invalid() const { return zh ? L"备份格式、版本或记录不合法，未更改当前数据。" : L"The backup format, version, or records are invalid. Your data has not changed."; }
  std::wstring backup_restored() const { return zh ? L"备份已恢复" : L"Backup restored"; }
  std::wstring backup_too_large() const { return zh ? L"备份不能超过 5 MB，当前数据未改变。" : L"Backups must be 5 MB or smaller. Your data has not changed."; }
  std::wstring device_saved() const { return zh ? L"设备已保存" : L"Device saved"; }
  std::wstring preferences_updated() const { return zh ? L"偏好已更新" : L"Preferences updated"; }
  std::wstring goal_enabled_label() const { return zh ? L"设置每天愿意付的金额" : L"Set what you would pay per day"; }
  std::wstring goal_section_title() const { return zh ? L"你的回本目标" : L"Your personal value goal"; }
  std::wstring daily_value() const { return zh ? L"每日价值" : L"Daily value"; }
  std::wstring daily_value_help() const { return zh ? L"例如每天 2 元。累计使用价值达到购买价格时，视为回本。" : L"For example, 2 units per day. Your goal is met when accumulated value reaches the purchase price."; }
  std::wstring notes_optional() const { return zh ? L"添加备注（可选）" : L"Notes (optional)"; }
  std::wstring form_name_required() const { return zh ? L"设备名称 · 必填" : L"Device name · required"; }
  std::wstring form_price_required() const { return zh ? L"购买价格 · 必填" : L"Purchase price · required"; }
  std::wstring form_date_required() const { return zh ? L"购买日期 · 必填" : L"Purchase date · required"; }
  std::wstring save_device_button() const { return zh ? L"保存设备" : L"Save device"; }
  std::wstring saving_short() const { return zh ? L"正在保存…" : L"Saving…"; }
  std::wstring retry_save() const { return zh ? L"重试保存" : L"Retry save"; }
  std::wstring companion_section() const { return zh ? L"移动端伴随" : L"Mobile companion"; }
  std::wstring companion_enable() const { return zh ? L"允许移动端连接" : L"Allow mobile connections"; }
  std::wstring companion_enable_help() const { return zh ? L"在本地网络开启伴随通道；手机与本机配对后可读取和编辑同一份数据。默认关闭。" : L"Runs the companion channel on your local network. A paired phone reads and edits the same data. Off by default."; }
  std::wstring companion_status_on() const { return zh ? L"伴随通道运行中" : L"Companion channel running"; }
  std::wstring companion_status_off() const { return zh ? L"伴随通道已关闭" : L"Companion channel off"; }
  std::wstring companion_open_window() const { return zh ? L"打开配对窗口" : L"Open pairing window"; }
  std::wstring companion_window_hint() const { return zh ? L"配对窗口五分钟后关闭。" : L"The pairing window closes after five minutes."; }
  std::wstring companion_prompt_title() const { return zh ? L"手机配对请求" : L"Phone pairing request"; }
  std::wstring companion_prompt_body() const { return zh ? L"在手机上确认同一个六位码，两侧一致才批准。" : L"Confirm the same six-digit code on the phone. Approve only if both screens match."; }
  std::wstring companion_approve() const { return zh ? L"批准" : L"Approve"; }
  std::wstring companion_reject() const { return zh ? L"拒绝" : L"Reject"; }
  std::wstring companion_paired_label() const { return zh ? L"已配对设备" : L"Paired devices"; }
  std::wstring companion_remove() const { return zh ? L"移除" : L"Remove"; }
  std::wstring companion_empty_paired() const { return zh ? L"还没有已配对的移动设备。" : L"No paired mobile devices yet."; }
  std::wstring companion_fingerprint() const { return zh ? L"服务器指纹" : L"Server fingerprint"; }
  std::wstring companion_failed() const { return zh ? L"伴随通道出错" : L"Companion channel error"; }
  std::wstring companion_idle() const { return zh ? L"未连接桌面端" : L"Desktop not connected"; }
  std::wstring companion_connecting() const { return zh ? L"正在安全连接…" : L"Connecting securely…"; }
  std::wstring companion_confirm_code() const { return zh ? L"请确认配对码" : L"Confirm the pairing code"; }
  std::wstring companion_connected() const { return zh ? L"已建立安全会话" : L"Secure session established"; }
  std::wstring companion_session_header() const { return zh ? L"连接状态" : L"Connection"; }
  std::wstring companion_disconnect() const { return zh ? L"断开" : L"Disconnect"; }
  std::wstring companion_nearby() const { return zh ? L"附近的桌面端" : L"Nearby desktops"; }
  std::wstring companion_stop_scan() const { return zh ? L"停止扫描" : L"Stop scanning"; }
  std::wstring companion_scan() const { return zh ? L"扫描桌面端" : L"Scan for desktops"; }
  std::wstring companion_no_devices() const { return zh ? L"还没有发现桌面端。请确认桌面端已开启伴随通道，并处于同一网络。" : L"No desktops found yet. Make sure the desktop companion channel is on and both devices share a network."; }
  std::wstring companion_window_open() const { return zh ? L"配对窗口已打开" : L"Pairing window open"; }
  std::wstring companion_window_closed() const { return zh ? L"配对窗口未打开" : L"Pairing window closed"; }
  std::wstring companion_window_i_d_field() const { return zh ? L"配对窗口 ID（桌面端设置里复制）" : L"Pairing window ID (copy from desktop settings)"; }
  std::wstring companion_pair() const { return zh ? L"配对" : L"Pair"; }
  std::wstring companion_reconnect() const { return zh ? L"重新连接" : L"Reconnect"; }
};

inline Strings const& strings() {
  static Strings const value{chinese_ui()};
  return value;
}

}  // namespace payback::strings
