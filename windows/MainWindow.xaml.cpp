#include "pch.h"
#include "MainWindow.xaml.h"
#if __has_include("MainWindow.g.cpp")
#include "MainWindow.g.cpp"
#endif
#include "GeneratedBackend.hpp"
#include "HostHelpers.h"

<<<<<<< HEAD
#include "winrt/Windows.Storage.Pickers.h"  // backup save/open pickers

=======
#include <algorithm>
>>>>>>> leg/win-retrofit
#include <cmath>
#include <stdexcept>

namespace winrt::RivetHost::implementation {
namespace {

using namespace payback::host;
using payback::strings::Strings;

using Windows::Data::Json::JsonObject;
using Windows::Data::Json::JsonValue;

// Badge backdrop hue follows the device category, mirroring the mac
// DeviceIconBadge; "other" (and anything unknown) wears the accent soft tint.
winrt::Microsoft::UI::Xaml::Media::Brush category_brush(
    winrt::Microsoft::UI::Xaml::Controls::Grid const& contentRoot,
    std::wstring const& category) {
  wchar_t const* key = L"PaybackAccentSoftBrush";
  if (category == L"computer") {
    key = L"PaybackCatComputerBrush";
  } else if (category == L"phone") {
    key = L"PaybackCatPhoneBrush";
  } else if (category == L"tablet") {
    key = L"PaybackCatTabletBrush";
  } else if (category == L"watch") {
    key = L"PaybackCatWatchBrush";
  } else if (category == L"audio") {
    key = L"PaybackCatAudioBrush";
  } else if (category == L"camera") {
    key = L"PaybackCatCameraBrush";
  } else if (category == L"gaming") {
    key = L"PaybackCatGamingBrush";
  } else if (category == L"appliance") {
    key = L"PaybackCatApplianceBrush";
  } else if (category == L"accessory") {
    key = L"PaybackCatAccessoryBrush";
  }
  return theme_brush(contentRoot, key);
}

// Rounded emoji tile (mac DeviceIconBadge): the corner radius tracks the
// size so small sidebar badges and the large detail badge keep one shape.
winrt::Microsoft::UI::Xaml::Controls::Border make_badge(
    winrt::Microsoft::UI::Xaml::Controls::Grid const& contentRoot,
    std::wstring const& icon, std::wstring const& category, double size) {
  winrt::Microsoft::UI::Xaml::Controls::Border badge;
  badge.Width(size);
  badge.Height(size);
  double const corner = size * 0.26;
  badge.CornerRadius(
      winrt::Microsoft::UI::Xaml::CornerRadius{corner, corner, corner, corner});
  badge.Background(category_brush(contentRoot, category));
  winrt::Microsoft::UI::Xaml::Controls::TextBlock glyph;
  glyph.Text(icon);
  glyph.FontSize(size * 0.55);
  glyph.HorizontalAlignment(winrt::Microsoft::UI::Xaml::HorizontalAlignment::Center);
  glyph.VerticalAlignment(winrt::Microsoft::UI::Xaml::VerticalAlignment::Center);
  badge.Child(glyph);
  return badge;
}

// Prototype display names for stored category values: the seven form
// options map onto engine values (accessory = keyboard, appliance =
// coffee); legacy stored values keep their own labels so an edit never
// silently rewrites them (design/DESIGN.md).
std::wstring category_display_name(std::wstring const& category) {
  Strings const& s = strings();
  if (category == L"computer") return s.category_computer();
  if (category == L"phone") return s.category_phone();
  if (category == L"tablet") return s.category_tablet();
  if (category == L"watch") return s.category_watch();
  if (category == L"audio") return s.category_audio();
  if (category == L"camera") return s.category_camera();
  if (category == L"gaming") return s.category_gaming();
  if (category == L"appliance") return s.category_appliance();
  if (category == L"accessory") return s.category_accessory();
  return s.category_other();
}

// thresholds in major units matching the engine's cpd ladder
// (docs/data-format.md: cpd-10 achieved under 10.00 major per day)
double cpd_threshold_major(std::wstring const& key) {
  if (key == L"cpd-10") return 10.0;
  if (key == L"cpd-5") return 5.0;
  if (key == L"cpd-2") return 2.0;
  if (key == L"cpd-1") return 1.0;
  if (key == L"cpd-05") return 0.5;
  return 0.0;
}

}  // namespace

// ---------- construction ----------------------------------------------------

MainWindow::MainWindow() {
  payback::host::load_language_override();
  InitializeComponent();
  Title(L"Payback");
  // Same floor as the macOS host; below it the summary grid and the toolbar
  // start crowding each other instead of reflowing.
  if (auto const presenter =
          AppWindow().Presenter().try_as<Microsoft::UI::Windowing::OverlappedPresenter>()) {
    presenter.PreferredMinimumWidth(980);
    presenter.PreferredMinimumHeight(600);
  }
  StatusMessage().Text(strings().starting_backend());
  ApplyLanguage();
  auto const weak = get_weak();
  // Window is not a FrameworkElement; the theme lives on the content root
  // (a Grid), which exposes ActualTheme/ActualThemeChanged.
  auto contentRoot = Content().as<Microsoft::UI::Xaml::Controls::Grid>();
  contentRoot.ActualThemeChanged([weak](auto&&, auto&&) {
    if (auto window = weak.get()) {
      window->RenderDocumentFromCache();
    }
  });
  InitializeBackendAsync();
}

winrt::fire_and_forget MainWindow::InitializeBackendAsync() {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = std::make_shared<rivet::windows::Backend>(runtime_config());

  try {
    // Booting the embedded runtime can block on file I/O, so only startup is
    // moved off the UI thread. RPC traffic below is completion-driven.
    co_await winrt::resume_background();
    backend->start();

    dispatcher.TryEnqueue([weak, backend = std::move(backend)]() mutable {
      if (auto window = weak.get()) {
        window->backend_ = std::move(backend);
        window->SetReadyUi();
        window->LoadAllAsync();
      } else {
        // Never destroy the last Backend reference on its own reader thread.
        std::thread([backend = std::move(backend)]() mutable {
          backend->stop();
        }).detach();
      }
    });
  } catch (std::exception const& e) {
    auto message = std::string(e.what());
    dispatcher.TryEnqueue([weak, message = std::move(message)] {
      if (auto window = weak.get()) {
        window->SetErrorUi(message);
      }
    });
  }
}

// ---------- language ----------------------------------------------------------

// Re-apply every static label; called on language change and at startup (the
// persisted override must win over the XAML's zh defaults). The device list
// re-renders from the in-memory document (no backend round trip).
void MainWindow::ApplyLanguage() {
  Strings const& s = strings();
  // 2026-11 redesign summary: investment hero + mini stats; the earned
  // tile and the rotating quips are retired with the terminology contract
  InvestmentEyebrow().Text(s.investment_eyebrow());
  SummaryCaption().Text(s.investment_caption());
  DailyTotalLabel().Text(s.daily_cost_total());
  DeviceCountLabel().Text(s.devices_tracked());
  // borderless toolbar icons: the string acts as both label and tooltip
  auto const label_button = [](auto const& button, std::wstring const& text) {
    button.Label(winrt::hstring(text));
    Microsoft::UI::Xaml::Controls::ToolTipService::SetToolTip(
        button, winrt::box_value(winrt::hstring(text)));
  };
  label_button(AddButton(), s.add_device());
  label_button(EditButton(), s.edit());
  label_button(DeleteButton(), s.remove());
  label_button(SettingsButton(), s.settings_title());
  label_button(HelpButton(), s.help_menu());
  MenuCheckUpdates().Text(winrt::hstring(s.check_updates_menu()));
  MenuAbout().Text(winrt::hstring(s.about_menu()));
  SortBox().Items().GetAt(0).as<Microsoft::UI::Xaml::Controls::ComboBoxItem>()
      .Content(winrt::box_value(winrt::hstring(s.sort_added())));
  SortBox().Items().GetAt(1).as<Microsoft::UI::Xaml::Controls::ComboBoxItem>()
      .Content(winrt::box_value(winrt::hstring(s.sort_date())));
  SortBox().Items().GetAt(2).as<Microsoft::UI::Xaml::Controls::ComboBoxItem>()
      .Content(winrt::box_value(winrt::hstring(s.sort_daily_cost())));
  EmptyTitleText().Text(s.empty_title());
  EmptyHintText().Text(s.empty_hint());
  EmptyAddButton().Content(winrt::box_value(winrt::hstring(s.add_first_device())));
  UndoButton().Content(winrt::box_value(winrt::hstring(s.undo())));
  RenderDocumentFromCache();
}

void MainWindow::SetReadyUi() {
  // "backend ready" is not news worth a permanent strip: the bar only
  // exists while it carries something actionable (errors, update progress,
  // the daily digest), then it gives the row back to the device list.
  StatusBar().IsOpen(false);
  AddButton().IsEnabled(true);
  EmptyAddButton().IsEnabled(true);
  UpdateToolbarEnabled();
  StartSyncPolling();
}

void MainWindow::SetErrorUi(std::string const& message) {
  StatusBar().IsOpen(true);
  StatusBar().Severity(Microsoft::UI::Xaml::Controls::InfoBarSeverity::Error);
  StatusMessage().Text(winrt::to_hstring(message));
}

void MainWindow::ShowSuccess(std::wstring const& message) {
  StatusBar().IsOpen(true);
  StatusBar().Severity(Microsoft::UI::Xaml::Controls::InfoBarSeverity::Success);
  StatusMessage().Text(message);
}

void MainWindow::ShowError(std::wstring const& message) {
  SetErrorUi(wide_to_utf8(message));
}

// ---------- data loading -----------------------------------------------------

void MainWindow::LoadAllAsync() {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  try {
    rivet_app::API api(*backend);
    (void)api.load_all_async([dispatcher, weak](rivet_app::Result<rivet::Bytes> result) {
      std::vector<std::uint8_t> payload;
      std::string failure;
      try {
        payload = result.get();
      } catch (std::exception const& e) {
        failure = e.what();
      }
      dispatcher.TryEnqueue([weak, payload = std::move(payload),
                             failure = std::move(failure)] {
        if (auto window = weak.get()) {
          if (!failure.empty()) {
            window->SetErrorUi(failure);
          } else {
            window->RenderDocument(payload);
          }
        }
      });
    });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

void MainWindow::RenderDocument(std::vector<std::uint8_t> const& payload) {
  auto const utf8_text = std::string(payload.begin(), payload.end());
  auto const wide = to_utf8_as_wide(utf8_text);
  auto parsed = JsonObject::Parse(wide);

  auto const settings = field(parsed, L"settings");
  auto const summary = field(parsed, L"summary");
  auto const devices = field(parsed, L"devices");

  document_.currency =
      as_string(field(settings, L"currency"), L"CNY");
  document_.update_auto_check = as_bool(field(settings, L"updateAutoCheck"), true);
  document_.total_spent_minor = as_int(field(summary, L"totalSpentMinor"));
  document_.earned_total_minor = as_double(field(summary, L"earnedTotalMinor"));
  document_.avg_cost_per_day_minor =
      as_double(field(summary, L"avgCostPerDayMinor"));
  document_.daily_cost_sum_minor =
      as_double(field(summary, L"dailyCostSumMinor"));
  document_.device_count = static_cast<int>(as_int(field(summary, L"deviceCount")));
  document_.trash_count = static_cast<int>(as_int(field(parsed, L"trashCount")));
  document_.currency_groups.clear();
  auto const groups = field(summary, L"currencyGroups");
  if (groups.ValueType() == Windows::Data::Json::JsonValueType::Array) {
    for (auto const& item : groups.GetArray()) {
      if (item.ValueType() != Windows::Data::Json::JsonValueType::Object) {
        continue;
      }
      document_.currency_groups.push_back(MainWindow::CurrencyGroup{
          as_string(field(item, L"currency")),
          as_int(field(item, L"totalSpentMinor")),
          as_double(field(item, L"earnedTotalMinor")),
          as_double(field(item, L"avgCostPerDayMinor")),
          as_double(field(item, L"dailyCostSumMinor"))});
    }
  }

  document_.devices.clear();
  if (devices.ValueType() == Windows::Data::Json::JsonValueType::Array) {
    for (auto const& item : devices.GetArray()) {
      DeviceRow row;
      row.id = as_string(field(item, L"id"));
      row.name = as_string(field(item, L"name"));
      row.icon = as_string(field(item, L"icon"), L"📦");
      row.category = as_string(field(item, L"category"));
      row.price_minor = as_int(field(item, L"priceMinor"));
      row.currency = as_string(field(item, L"currency"), document_.currency);
      row.purchase_date = as_string(field(item, L"purchaseDate"));
      row.created_at = as_string(field(item, L"createdAt"));
      auto const willing = field(item, L"willingPerDayMinor");
      if (willing.ValueType() == Windows::Data::Json::JsonValueType::Number) {
        row.has_willing = true;
        row.willing_per_day_minor = as_int(willing);
      }
      row.notes = as_string(field(item, L"notes"));

      auto const computed = field(item, L"computed");
      row.computed.days_held = as_int(field(computed, L"daysHeld"), 1);
      row.computed.cost_per_day_minor = as_double(field(computed, L"costPerDayMinor"));
      row.computed.willing_set = as_bool(field(computed, L"willingSet"));
      auto const earned = field(computed, L"earnedMinor");
      if (earned.ValueType() == Windows::Data::Json::JsonValueType::Number) {
        row.computed.has_earned = true;
        row.computed.earned_minor = earned.GetNumber();
      }
      auto const progress = field(computed, L"paybackProgress");
      if (progress.ValueType() == Windows::Data::Json::JsonValueType::Number) {
        row.computed.has_progress = true;
        row.computed.payback_progress = progress.GetNumber();
      }
      row.computed.payback_eta = as_string(field(computed, L"paybackEta"));
      row.computed.paid_back = as_bool(field(computed, L"paidBack"));
      auto const milestones = field(computed, L"milestones");
      if (milestones.ValueType() == Windows::Data::Json::JsonValueType::Array) {
        for (auto const& entry : milestones.GetArray()) {
          Milestone milestone;
          milestone.key = as_string(field(entry, L"key"));
          milestone.achieved = as_bool(field(entry, L"achieved"));
          milestone.is_new = as_bool(field(entry, L"new"));
          row.computed.milestones.push_back(milestone);
        }
      }
      document_.devices.push_back(row);
    }
  }

  RenderSummary();
  RenderDeviceList();
  ShowCelebrations();

  ReportFailedInstall();

  // the backend throttles auto-checks to once every 4 hours; a launch-time
  // check stays silent unless an update is available (then the consent
  // dialog shows)
  if (!auto_check_done_) {
    auto_check_done_ = true;
    if (document_.update_auto_check) {
      AutoCheckUpdatesAsync();
    }
  }
  RunDailyDigest();
}

void MainWindow::RenderDocumentFromCache() {
  RenderSummary();
  RenderDeviceList();
}

// 2026-11 redesign sidebar summary: the investment hero renders the
// default currency's group only; mixed portfolios keep the note instead of
// any combined money value (#23, design/DESIGN.md).
void MainWindow::RenderSummary() {
  Strings const& s = strings();
  auto const contentRoot = Content().as<Microsoft::UI::Xaml::Controls::Grid>();

  CurrencyGroup const* group = nullptr;
  for (auto const& candidate : document_.currency_groups) {
    if (candidate.currency == document_.currency) {
      group = &candidate;
      break;
    }
  }

  std::wstring spent_text;
  if (group != nullptr) {
    spent_text = money(static_cast<double>(group->total_spent_minor),
                       group->currency);
  } else if (!document_.mixed_currency() &&
             document_.currency_groups.size() == 1) {
    // single group under a different code than the default currency (a
    // synced default change with old records): render that one group
    spent_text = money(
        static_cast<double>(document_.currency_groups.front().total_spent_minor),
        document_.currency_groups.front().currency);
  } else {
    spent_text = money(0.0, document_.currency);
  }
  TotalSpentText().Text(spent_text);

  std::wstring daily_text;
  if (group != nullptr) {
    daily_text = per_day(group->daily_cost_sum_minor, group->currency);
  } else {
    daily_text = per_day(0.0, document_.currency);
  }
  DailyTotalText().Text(daily_text);
  DeviceCountText().Text(std::to_wstring(document_.device_count));

  bool const mixed = document_.mixed_currency();
  MixedCurrencyNote().Text(s.mixed_currency_note());
  MixedCurrencyNote().Visibility(
      mixed ? Microsoft::UI::Xaml::Visibility::Visible
            : Microsoft::UI::Xaml::Visibility::Collapsed);
}

// Mixed portfolios never show one combined money value: the backend nulls
// the combined scalars and the tiles join the per-currency groups (#23).


// ---------- sidebar: device rows ----------------------------------------------

// Apple's answer to "browse a collection, inspect one item" is the nonmodal
// split (mac NavigationSplitView parity): each device is a selectable pane
// row, selection drives the detail pane in place, and the rich surface
// (curve, progress, milestones) lives one selection away in the detail.
void MainWindow::RenderDeviceList() {
  // The SortBox raises SelectionChanged while InitializeComponent is still
  // binding x:Name members, so the pane may not exist yet; the real render
  // happens once the backend document arrives.
  if (!NavView()) {
    return;
  }
  Strings const& s = strings();

  auto rows = document_.devices;
  if (sort_mode_ == 1) {
    // 最近购买: newest purchase first (design/DESIGN.md sort contract)
    std::sort(rows.begin(), rows.end(),
              [](DeviceRow const& a, DeviceRow const& b) {
                return a.purchase_date > b.purchase_date;
              });
  } else if (sort_mode_ == 2) {
    // 每日成本排序按币种分组，同组数值降序 (design/DESIGN.md)
    std::sort(rows.begin(), rows.end(),
              [](DeviceRow const& a, DeviceRow const& b) {
                if (a.currency != b.currency) {
                  return a.currency < b.currency;
                }
                return a.computed.cost_per_day_minor > b.computed.cost_per_day_minor;
              });
  }
  // sort_mode_ == 0 keeps the engine's deterministic merged order

  bool const empty = rows.empty();
  // the empty state replaces the whole split, the way the mac host does
  NavView().Visibility(empty ? Microsoft::UI::Xaml::Visibility::Collapsed
                             : Microsoft::UI::Xaml::Visibility::Visible);
  EmptyState().Visibility(empty ? Microsoft::UI::Xaml::Visibility::Visible
                                : Microsoft::UI::Xaml::Visibility::Collapsed);

  auto const contentRoot = Content().as<Microsoft::UI::Xaml::Controls::Grid>();
  auto items = NavView().MenuItems();
  suppress_selection_changed_ = true;
  items.Clear();

  for (auto const& row : rows) {
    auto item = Microsoft::UI::Xaml::Controls::NavigationViewItem();

    auto content = Microsoft::UI::Xaml::Controls::Grid();
    content.Padding({0, 2, 0, 2});
    content.ColumnDefinitions().Append(pixel_column(40));
    content.ColumnDefinitions().Append(star_column());
    content.ColumnDefinitions().Append(auto_column());

    auto badge = make_badge(contentRoot, row.icon, row.category, 34);
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(badge, 0);
    badge.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Center);
    content.Children().Append(badge);

    auto text = Microsoft::UI::Xaml::Controls::StackPanel();
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(text, 1);
    text.Margin({8, 0, 0, 0});
    text.Spacing(2);
    text.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Center);
    auto name = Microsoft::UI::Xaml::Controls::TextBlock();
    name.Text(row.name);
    name.FontSize(14);
    name.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
    name.TextTrimming(Microsoft::UI::Xaml::TextTrimming::CharacterEllipsis);
    text.Children().Append(name);
    auto cost = Microsoft::UI::Xaml::Controls::TextBlock();
    cost.Text(per_day(row.computed.cost_per_day_minor, row.currency));
    cost.FontSize(12);
    cost.Opacity(0.65);
    text.Children().Append(cost);
    content.Children().Append(text);

    // the prototype's trailing state-dot: green exactly when the goal is
    // met (design/DESIGN.md — green carries no other meaning)
    if (row.computed.paid_back) {
      auto dot = Microsoft::UI::Xaml::Shapes::Ellipse();
      dot.Width(7);
      dot.Height(7);
      dot.Fill(theme_brush(contentRoot, L"PaybackEarnBrush"));
      dot.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Center);
      dot.Margin({8, 0, 0, 0});
      Microsoft::UI::Xaml::Controls::Grid::SetColumn(dot, 2);
      content.Children().Append(dot);
    }

    // right-tap row menu: edit / delete, delete painted destructive
    auto const id = row.id;
    auto const weak = get_weak();
    auto menu = Microsoft::UI::Xaml::Controls::MenuFlyout();
    auto edit_item = Microsoft::UI::Xaml::Controls::MenuFlyoutItem();
    edit_item.Text(s.edit());
    edit_item.Click([weak, id](auto const&, auto const&) {
      if (auto window = weak.get()) {
        window->SaveDeviceAsync(true, id);
      }
    });
    auto remove_item = Microsoft::UI::Xaml::Controls::MenuFlyoutItem();
    remove_item.Text(s.remove());
    remove_item.Foreground(destructive_brush());
    remove_item.Click([weak, id](auto const&, auto const&) {
      if (auto window = weak.get()) {
        window->ShowDeleteConfirm(id);
      }
    });
    menu.Items().Append(edit_item);
    menu.Items().Append(remove_item);
    item.ContextFlyout(menu);

    item.Content(content);
    item.Tag(winrt::box_value(winrt::hstring(id)));
    items.Append(item);
  }

  // selection survives re-renders; a stale or fresh selection falls back to
  // the first device so the detail pane is never blank while devices exist
  std::wstring next;
  for (auto const& row : rows) {
    if (row.id == selected_device_id_) {
      next = row.id;
      break;
    }
  }
  if (next.empty() && !rows.empty()) {
    next = rows.front().id;
  }
  selected_device_id_ = next;
  if (next.empty()) {
    NavView().SelectedItem(nullptr);
  } else {
    for (std::uint32_t i = 0; i < items.Size(); ++i) {
      auto const candidate =
          items.GetAt(i).try_as<Microsoft::UI::Xaml::Controls::NavigationViewItem>();
      auto const tag = winrt::unbox_value_or<winrt::hstring>(candidate.Tag(), {});
      if (std::wstring(tag.c_str()) == next) {
        NavView().SelectedItem(candidate);
        break;
      }
    }
  }
  suppress_selection_changed_ = false;

  RenderDetail();
}

void MainWindow::NavView_SelectionChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Microsoft::UI::Xaml::Controls::NavigationViewSelectionChangedEventArgs const& args) {
  if (suppress_selection_changed_) {
    return;
  }
  auto const item =
      args.SelectedItem().try_as<Microsoft::UI::Xaml::Controls::NavigationViewItem>();
  if (!item) {
    return;
  }
  auto const tag = winrt::unbox_value_or<winrt::hstring>(item.Tag(), {});
  std::wstring const id(tag.c_str());
  if (id == selected_device_id_) {
    return;
  }
  selected_device_id_ = id;
  RenderDetail();
}

// ---------- detail pane -------------------------------------------------------

// The detail pane is pure content (mac DeviceDetail parity): identity header,
// stat tiles, cost curve, payback progress, milestone ladder. Its actions
// live in the toolbar and the row context menu, keeping this surface clean.
void MainWindow::RenderDetail() {
  if (!DetailPanel()) {
    return;
  }
  DetailPanel().Children().Clear();
  curve_ = nullptr;

  // nonmodal fallback: a stale or fresh selection reads as the first device,
  // so the pane is never blank while devices exist
  DeviceRow const* row = nullptr;
  for (auto const& candidate : document_.devices) {
    if (candidate.id == selected_device_id_) {
      row = &candidate;
      break;
    }
  }
  if (row == nullptr && !document_.devices.empty()) {
    row = &document_.devices.front();
  }
  UpdateToolbarEnabled();
  if (row == nullptr) {
    return;
  }

  Strings const& s = strings();
  auto const contentRoot = Content().as<Microsoft::UI::Xaml::Controls::Grid>();
  auto children = DetailPanel().Children();

  auto const make_card = [&contentRoot]() {
    Microsoft::UI::Xaml::Controls::Border card;
    card.CornerRadius({16, 16, 16, 16});
    card.Background(theme_brush(contentRoot, L"PaybackCardBrush"));
    card.BorderBrush(theme_brush(contentRoot, L"PaybackLineBrush"));
    card.BorderThickness({1, 1, 1, 1});
    card.Padding({28, 24, 28, 24});
    return card;
  };
  auto const muted = [&contentRoot]() {
    return Microsoft::UI::Xaml::Media::SolidColorBrush{
        theme_brush(contentRoot, L"PaybackMutedBrush")
            .as<winrt::Microsoft::UI::Xaml::Media::SolidColorBrush>()
            .Color()};
  };
  auto const ink = [&contentRoot]() {
    return Microsoft::UI::Xaml::Media::SolidColorBrush{
        theme_brush(contentRoot, L"PaybackInkBrush")
            .as<winrt::Microsoft::UI::Xaml::Media::SolidColorBrush>()
            .Color()};
  };
  auto const accent_solid = [&contentRoot]() {
    return Microsoft::UI::Xaml::Media::SolidColorBrush{
        theme_brush(contentRoot, L"PaybackAccentBrush")
            .as<winrt::Microsoft::UI::Xaml::Media::SolidColorBrush>()
            .Color()};
  };
  auto const earn_solid = [&contentRoot]() {
    return Microsoft::UI::Xaml::Media::SolidColorBrush{
        theme_brush(contentRoot, L"PaybackEarnBrush")
            .as<winrt::Microsoft::UI::Xaml::Media::SolidColorBrush>()
            .Color()};
  };

  // ----- head: category eyebrow + days together, name, price · date -----
  auto head = Microsoft::UI::Xaml::Controls::StackPanel();
  head.Spacing(8);
  auto eyebrow_text =
      category_display_name(row->category) + L" · " +
      replace_all(s.days_together(), L"{days}",
                  format_days(row->computed.days_held));
  auto eyebrow = Microsoft::UI::Xaml::Controls::TextBlock();
  eyebrow.Text(eyebrow_text);
  eyebrow.FontSize(13);
  eyebrow.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  eyebrow.Foreground(muted());
  head.Children().Append(eyebrow);
  auto title = Microsoft::UI::Xaml::Controls::TextBlock();
  title.Text(row->name);
  title.FontSize(26);
  title.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  title.TextWrapping(Microsoft::UI::Xaml::TextWrapping::WrapWholeWords);
  head.Children().Append(title);
  auto facts = Microsoft::UI::Xaml::Controls::TextBlock();
  facts.Text(money(static_cast<double>(row->price_minor), row->currency) +
             L" · " + s.purchased_on() + L" " + row->purchase_date);
  facts.FontSize(14);
  facts.Foreground(muted());
  head.Children().Append(facts);
  head.Margin({0, 0, 0, 24});
  children.Append(head);

  // ----- hero: today's daily cost | the personal value goal -----
  auto hero = make_card();
  auto hero_grid = Microsoft::UI::Xaml::Controls::Grid();
  hero_grid.ColumnDefinitions().Append(star_column());
  hero_grid.ColumnDefinitions().Append(auto_column());
  hero_grid.ColumnDefinitions().Append(star_column());

  auto hero_left = Microsoft::UI::Xaml::Controls::StackPanel();
  hero_left.Spacing(0);
  auto hero_label = Microsoft::UI::Xaml::Controls::TextBlock();
  hero_label.Text(s.hero_daily_label());
  hero_label.FontSize(14);
  hero_label.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  hero_label.Foreground(muted());
  hero_left.Children().Append(hero_label);
  auto hero_number_row = Microsoft::UI::Xaml::Controls::StackPanel();
  hero_number_row.Orientation(Microsoft::UI::Xaml::Controls::Orientation::Horizontal);
  hero_number_row.Spacing(4);
  hero_number_row.Margin({0, 10, 0, 0});
  auto hero_number = Microsoft::UI::Xaml::Controls::TextBlock();
  hero_number.Text(per_day(row->computed.cost_per_day_minor, row->currency));
  hero_number.FontSize(44);
  hero_number.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  hero_number.CharacterSpacing(-150);
  hero_number.Foreground(ink());
  hero_number.TextTrimming(Microsoft::UI::Xaml::TextTrimming::CharacterEllipsis);
  hero_number_row.Children().Append(hero_number);
  auto hero_unit = Microsoft::UI::Xaml::Controls::TextBlock();
  hero_unit.Text(s.per_day());
  hero_unit.FontSize(15);
  hero_unit.Foreground(muted());
  hero_unit.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Bottom);
  hero_number_row.Children().Append(hero_unit);
  hero_left.Children().Append(hero_number_row);
  auto hero_caption = Microsoft::UI::Xaml::Controls::TextBlock();
  hero_caption.Text(s.hero_daily_caption());
  hero_caption.FontSize(14);
  hero_caption.Foreground(muted());
  hero_caption.Margin({0, 10, 0, 0});
  hero_left.Children().Append(hero_caption);
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(hero_left, 0);
  hero_grid.Children().Append(hero_left);

  // the vertical divider between the two hero halves (prototype .goal)
  auto divider = Microsoft::UI::Xaml::Controls::Border();
  divider.Width(1);
  divider.Background(theme_brush(contentRoot, L"PaybackLineBrush"));
  divider.Margin({24, 0, 24, 0});
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(divider, 1);
  hero_grid.Children().Append(divider);

  auto hero_right = Microsoft::UI::Xaml::Controls::StackPanel();
  hero_right.Spacing(0);
  auto goal_head = Microsoft::UI::Xaml::Controls::TextBlock();
  goal_head.FontSize(14);
  goal_head.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  goal_head.Foreground(muted());
  if (row->has_willing) {
    goal_head.Text(row->computed.paid_back ? s.goal_met_heading()
                                           : s.goal_remaining_heading());
    hero_right.Children().Append(goal_head);

    auto goal_number_row =
        Microsoft::UI::Xaml::Controls::StackPanel();
    goal_number_row.Orientation(
        Microsoft::UI::Xaml::Controls::Orientation::Horizontal);
    goal_number_row.Spacing(6);
    goal_number_row.Margin({0, 10, 0, 0});
    if (row->computed.paid_back) {
      auto check = Microsoft::UI::Xaml::Controls::FontIcon();
      check.Glyph(L"\uE73E");
      check.FontSize(22);
      check.Foreground(earn_solid());
      goal_number_row.Children().Append(check);
      auto met = Microsoft::UI::Xaml::Controls::TextBlock();
      met.Text(s.paid_back());
      met.FontSize(28);
      met.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
      met.Foreground(earn_solid());
      goal_number_row.Children().Append(met);
    } else {
      auto remaining = Microsoft::UI::Xaml::Controls::TextBlock();
      remaining.Text(format_days(remaining_goal_days(*row)));
      remaining.FontSize(28);
      remaining.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
      remaining.Foreground(accent_solid());
      goal_number_row.Children().Append(remaining);
      auto unit = Microsoft::UI::Xaml::Controls::TextBlock();
      unit.Text(s.days());
      unit.FontSize(15);
      unit.Foreground(muted());
      unit.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Bottom);
      goal_number_row.Children().Append(unit);
    }
    hero_right.Children().Append(goal_number_row);

    auto bar = Microsoft::UI::Xaml::Controls::ProgressBar();
    bar.Minimum(0);
    bar.Maximum(100);
    double const progress =
        std::min(std::max(row->computed.payback_progress, 0.0), 1.0) * 100.0;
    bar.Value(progress);
    bar.CornerRadius({999, 999, 999, 999});
    bar.Height(6);
    bar.Margin({0, 14, 0, 0});
    bar.Foreground(row->computed.paid_back ? earn_solid() : accent_solid());
    hero_right.Children().Append(bar);

    auto based_on = Microsoft::UI::Xaml::Controls::TextBlock();
    based_on.Text(replace_all(
        s.goal_based_on(), L"{amount}",
        money(static_cast<double>(row->willing_per_day_minor), row->currency)));
    based_on.FontSize(14);
    based_on.Foreground(muted());
    based_on.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    based_on.Margin({0, 12, 0, 0});
    hero_right.Children().Append(based_on);
    if (row->computed.paid_back && row->computed.has_earned) {
      auto extra = Microsoft::UI::Xaml::Controls::TextBlock();
      extra.Text(replace_all(
          s.goal_extra(), L"{amount}",
          money(std::max(row->computed.earned_minor, 0.0), row->currency)));
      extra.FontSize(14);
      extra.Foreground(muted());
      extra.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
      extra.Margin({0, 6, 0, 0});
      hero_right.Children().Append(extra);
    }
  } else {
    goal_head.Text(s.goal_met_heading());
    hero_right.Children().Append(goal_head);
    auto question = Microsoft::UI::Xaml::Controls::TextBlock();
    question.Text(s.goal_question());
    question.FontSize(19);
    question.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
    question.Foreground(ink());
    question.Margin({0, 10, 0, 0});
    hero_right.Children().Append(question);
    auto hint = Microsoft::UI::Xaml::Controls::TextBlock();
    hint.Text(s.goal_set_hint());
    hint.FontSize(14);
    hint.Foreground(muted());
    hint.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    hint.Margin({0, 6, 0, 0});
    hero_right.Children().Append(hint);
  }
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(hero_right, 2);
  hero_grid.Children().Append(hero_right);
  hero.Child(hero_grid);
  hero.Margin({0, 0, 0, 24});
  children.Append(hero);

  // ----- cost curve card -----
  auto curve_card = Microsoft::UI::Xaml::Controls::Border();
  curve_card.Padding({0, 0, 0, 24});
  curve_card.BorderThickness({0, 0, 0, 1});
  curve_card.BorderBrush(theme_brush(contentRoot, L"PaybackLineBrush"));
  auto curve_stack = Microsoft::UI::Xaml::Controls::StackPanel();
  curve_stack.Spacing(0);
  auto curve_head = Microsoft::UI::Xaml::Controls::Grid();
  curve_head.ColumnDefinitions().Append(star_column());
  curve_head.ColumnDefinitions().Append(auto_column());
  auto curve_title = Microsoft::UI::Xaml::Controls::TextBlock();
  curve_title.Text(s.chart_title());
  curve_title.FontSize(19);
  curve_title.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  curve_title.Foreground(ink());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(curve_title, 0);
  curve_head.Children().Append(curve_title);
  auto curve_subtitle = Microsoft::UI::Xaml::Controls::TextBlock();
  curve_subtitle.Text(replace_all(
      s.chart_subtitle(), L"{days}", format_days(row->computed.days_held)));
  curve_subtitle.FontSize(13);
  curve_subtitle.Foreground(muted());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(curve_subtitle, 1);
  curve_head.Children().Append(curve_subtitle);
  curve_stack.Children().Append(curve_head);

  auto canvas = Microsoft::UI::Xaml::Controls::Canvas();
  canvas.Height(160);
  canvas.Margin({0, 16, 0, 0});
  curve_ = std::make_shared<CurveState>();
  curve_->price_minor = row->price_minor;
  curve_->days_held = row->computed.days_held;
  curve_->canvas = canvas;

  auto const accent_color = theme_brush(contentRoot, L"PaybackAccentBrush")
                                .as<winrt::Microsoft::UI::Xaml::Media::SolidColorBrush>()
                                .Color();
  auto const with_alpha = [&accent_color](std::uint8_t alpha) {
    winrt::Windows::UI::Color color = accent_color;
    color.A = alpha;
    return color;
  };

  auto fill_shape = Microsoft::UI::Xaml::Shapes::Polygon();
  auto fill_brush = winrt::Microsoft::UI::Xaml::Media::SolidColorBrush{
      with_alpha(0x2E)};
  fill_shape.Fill(fill_brush);

  auto line_shape = Microsoft::UI::Xaml::Shapes::Polyline();
  line_shape.Stroke(accent_solid());
  line_shape.StrokeThickness(3);
  line_shape.StrokeStartLineCap(Microsoft::UI::Xaml::Media::PenLineCap::Round);
  line_shape.StrokeEndLineCap(Microsoft::UI::Xaml::Media::PenLineCap::Round);
  line_shape.StrokeLineJoin(Microsoft::UI::Xaml::Media::PenLineJoin::Round);

  auto dot = Microsoft::UI::Xaml::Shapes::Ellipse();
  dot.Width(8);
  dot.Height(8);
  dot.Fill(accent_solid());

  curve_->fill = fill_shape;
  curve_->line = line_shape;
  curve_->dot = dot;
  canvas.Children().Append(fill_shape);
  canvas.Children().Append(line_shape);
  canvas.Children().Append(dot);
  canvas.SizeChanged([weak = get_weak(), curve = curve_](auto&&, auto&&) {
    if (auto window = weak.get()) {
      window->UpdateCurveGeometry(*curve);
    }
  });
  curve_stack.Children().Append(canvas);

  auto chart_labels = Microsoft::UI::Xaml::Controls::Grid();
  chart_labels.ColumnDefinitions().Append(star_column());
  chart_labels.ColumnDefinitions().Append(auto_column());
  chart_labels.Margin({0, 8, 0, 0});
  auto day_one = Microsoft::UI::Xaml::Controls::TextBlock();
  day_one.Text(replace_all(
      s.chart_day_one(), L"{amount}",
      money(static_cast<double>(row->price_minor), row->currency)));
  day_one.FontSize(13);
  day_one.Foreground(muted());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(day_one, 0);
  chart_labels.Children().Append(day_one);
  auto today = Microsoft::UI::Xaml::Controls::TextBlock();
  today.Text(replace_all(
      s.chart_today(), L"{amount}",
      per_day(row->computed.cost_per_day_minor, row->currency)));
  today.FontSize(13);
  today.Foreground(muted());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(today, 1);
  chart_labels.Children().Append(today);
  curve_stack.Children().Append(chart_labels);

  auto chart_note = Microsoft::UI::Xaml::Controls::TextBlock();
  chart_note.Text(s.chart_note());
  chart_note.FontSize(14);
  chart_note.Foreground(muted());
  chart_note.Margin({0, 12, 0, 0});
  curve_stack.Children().Append(chart_note);
  curve_card.Child(curve_stack);
  children.Append(curve_card);

  // ----- milestones | method (prototype .bottom-grid) -----
  auto bottom = Microsoft::UI::Xaml::Controls::Grid();
  bottom.ColumnSpacing(32);
  bottom.Margin({0, 32, 0, 0});
  {
    Microsoft::UI::Xaml::Controls::ColumnDefinition wide;
    wide.Width(winrt::Microsoft::UI::Xaml::GridLength{
        13, winrt::Microsoft::UI::Xaml::GridUnitType::Star});
    Microsoft::UI::Xaml::Controls::ColumnDefinition narrow;
    narrow.Width(winrt::Microsoft::UI::Xaml::GridLength{
        10, winrt::Microsoft::UI::Xaml::GridUnitType::Star});
    bottom.ColumnDefinitions().Append(wide);
    bottom.ColumnDefinitions().Append(narrow);
  }

  auto milestone_stack = Microsoft::UI::Xaml::Controls::StackPanel();
  milestone_stack.Spacing(12);
  auto milestone_head = Microsoft::UI::Xaml::Controls::Grid();
  milestone_head.ColumnDefinitions().Append(star_column());
  milestone_head.ColumnDefinitions().Append(auto_column());
  auto milestone_title = Microsoft::UI::Xaml::Controls::TextBlock();
  milestone_title.Text(s.milestones_title());
  milestone_title.FontSize(19);
  milestone_title.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  milestone_title.Foreground(ink());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(milestone_title, 0);
  milestone_head.Children().Append(milestone_title);
  int achieved_days = 0;
  for (auto const& milestone : row->computed.milestones) {
    if (milestone.key.rfind(L"days-", 0) == 0 && milestone.achieved) {
      ++achieved_days;
    }
  }
  auto milestone_count = Microsoft::UI::Xaml::Controls::TextBlock();
  milestone_count.Text(std::to_wstring(achieved_days) + L" / 3");
  milestone_count.FontSize(14);
  milestone_count.Foreground(muted());
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(milestone_count, 1);
  milestone_head.Children().Append(milestone_count);
  milestone_stack.Children().Append(milestone_head);

  // the prototype's ladder: only the three days-together milestones; cost
  // thresholds live in the expander below
  for (auto const& milestone : row->computed.milestones) {
    if (milestone.key.rfind(L"days-", 0) != 0) {
      continue;
    }
    auto line = Microsoft::UI::Xaml::Controls::Grid();
    line.ColumnDefinitions().Append(star_column());
    line.ColumnDefinitions().Append(auto_column());
    auto left = Microsoft::UI::Xaml::Controls::StackPanel();
    left.Orientation(Microsoft::UI::Xaml::Controls::Orientation::Horizontal);
    left.Spacing(12);
    auto icon = Microsoft::UI::Xaml::Controls::FontIcon();
    icon.Glyph(milestone.achieved ? L"\uE73E" : L"\uE76C");
    icon.FontSize(13);
    icon.Foreground(milestone.achieved ? earn_solid() : muted());
    left.Children().Append(icon);
    auto label = Microsoft::UI::Xaml::Controls::TextBlock();
    std::wstring const thousand =
        milestone.key == L"days-1000" ? L"1,000"
        : milestone.key == L"days-365" ? L"365"
                                       : L"100";
    label.Text(replace_all(s.days_together(), L"{days}", thousand));
    label.FontSize(14);
    label.Foreground(milestone.achieved ? ink() : muted());
    left.Children().Append(label);
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(left, 0);
    line.Children().Append(left);
    auto suffix = Microsoft::UI::Xaml::Controls::TextBlock();
    if (milestone.achieved) {
      suffix.Text(s.milestone_reached());
      suffix.Foreground(earn_solid());
    } else {
      int const target = milestone.key == L"days-1000" ? 1000
                         : milestone.key == L"days-365" ? 365
                                                        : 100;
      auto const remaining =
          std::max(target - static_cast<int>(row->computed.days_held), 1);
      suffix.Text(replace_all(s.milestone_days_to_go(), L"{days}",
                              format_days(remaining)));
      suffix.Foreground(muted());
    }
    suffix.FontSize(13);
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(suffix, 1);
    line.Children().Append(suffix);
    milestone_stack.Children().Append(line);
  }

  auto cost_expander = Microsoft::UI::Xaml::Controls::Expander();
  cost_expander.Header(winrt::box_value(winrt::hstring(s.cost_milestones_title())));
  cost_expander.HorizontalContentAlignment(
      Microsoft::UI::Xaml::HorizontalAlignment::Stretch);
  cost_expander.Margin({0, 8, 0, 0});
  auto cost_lines = Microsoft::UI::Xaml::Controls::StackPanel();
  cost_lines.Spacing(6);
  for (auto const& milestone : row->computed.milestones) {
    if (milestone.key.rfind(L"cpd-", 0) != 0) {
      continue;
    }
    double const threshold_major = cpd_threshold_major(milestone.key);
    auto line = Microsoft::UI::Xaml::Controls::TextBlock();
    line.Text((milestone.achieved ? s.milestone_reached()
                                  : s.cost_milestone_not_yet()) +
              L" · " +
              replace_all(s.cost_milestone_below(), L"{amount}",
                          money(threshold_major * 100, row->currency)) +
              s.per_day());
    line.FontSize(14);
    line.Foreground(muted());
    cost_lines.Children().Append(line);
  }
  cost_expander.Content(cost_lines);
  milestone_stack.Children().Append(cost_expander);
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(milestone_stack, 0);
  bottom.Children().Append(milestone_stack);

  auto method_stack = Microsoft::UI::Xaml::Controls::StackPanel();
  method_stack.Spacing(8);
  auto method_title = Microsoft::UI::Xaml::Controls::TextBlock();
  method_title.Text(s.method_title());
  method_title.FontSize(19);
  method_title.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
  method_title.Foreground(ink());
  method_stack.Children().Append(method_title);
  auto intro1 = Microsoft::UI::Xaml::Controls::TextBlock();
  intro1.Text(s.method_intro1());
  intro1.FontSize(14);
  intro1.Foreground(muted());
  intro1.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  intro1.Margin({0, 8, 0, 0});
  method_stack.Children().Append(intro1);
  auto intro2 = Microsoft::UI::Xaml::Controls::TextBlock();
  intro2.Text(s.method_intro2());
  intro2.FontSize(14);
  intro2.Foreground(muted());
  intro2.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  method_stack.Children().Append(intro2);
  auto calc_expander = Microsoft::UI::Xaml::Controls::Expander();
  calc_expander.Header(winrt::box_value(winrt::hstring(s.method_calc_title())));
  calc_expander.HorizontalContentAlignment(
      Microsoft::UI::Xaml::HorizontalAlignment::Stretch);
  calc_expander.Margin({0, 8, 0, 0});
  auto calc_lines = Microsoft::UI::Xaml::Controls::StackPanel();
  calc_lines.Spacing(6);
  auto calc_days = Microsoft::UI::Xaml::Controls::TextBlock();
  calc_days.Text(s.method_calc_days());
  calc_days.FontSize(14);
  calc_days.Foreground(muted());
  calc_days.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  calc_lines.Children().Append(calc_days);
  auto calc_reset = Microsoft::UI::Xaml::Controls::TextBlock();
  calc_reset.Text(s.method_calc_reset());
  calc_reset.FontSize(14);
  calc_reset.Foreground(muted());
  calc_reset.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  calc_lines.Children().Append(calc_reset);
  calc_expander.Content(calc_lines);
  method_stack.Children().Append(calc_expander);
  Microsoft::UI::Xaml::Controls::Grid::SetColumn(method_stack, 1);
  bottom.Children().Append(method_stack);
  children.Append(bottom);

  if (!row->notes.empty()) {
    auto notes = Microsoft::UI::Xaml::Controls::StackPanel();
    notes.Spacing(10);
    notes.Margin({0, 32, 0, 0});
    auto notes_title = Microsoft::UI::Xaml::Controls::TextBlock();
    notes_title.Text(s.notes_title());
    notes_title.FontSize(19);
    notes_title.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
    notes_title.Foreground(ink());
    notes.Children().Append(notes_title);
    auto notes_body = Microsoft::UI::Xaml::Controls::TextBlock();
    notes_body.Text(row->notes);
    notes_body.FontSize(14);
    notes_body.Foreground(muted());
    notes_body.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    notes.Children().Append(notes_body);
    children.Append(notes);
  }
}

// Curve geometry mirrors the mac CostCurve math: day 1 carries the whole
// price at the top edge and the line decays downward (never rises), and the
// x axis stretches to at least 30 days so a fresh purchase does not fill
// the whole card.
void MainWindow::UpdateCurveGeometry(CurveState& curve) {
  auto const canvas = curve.canvas;
  if (!canvas) {
    return;
  }
  double const width = canvas.ActualWidth();
  double const height = canvas.ActualHeight();
  if (width <= 0.0 || height <= 0.0) {
    return;
  }
  auto const max_days = std::max<std::int64_t>(curve.days_held, 30);
  auto const max_value =
      static_cast<double>(std::max<std::int64_t>(curve.price_minor, 1));

  auto const points = curve.line.Points();
  points.Clear();
  auto const fill_points = curve.fill.Points();
  fill_points.Clear();
  if (curve.days_held > 1) {
    for (std::int64_t day = 1; day <= curve.days_held; ++day) {
      double const x = static_cast<double>(day - 1) /
                       static_cast<double>(max_days - 1) * width;
      // day 1 carries the whole price at the top edge; the curve only ever
      // decays downward from there (超衰减曲线, design.md — never rises)
      double const y =
          height * (1.0 - (static_cast<double>(curve.price_minor) /
                           static_cast<double>(day)) /
                              max_value);
      auto const point = winrt::Windows::Foundation::Point{
          static_cast<float>(std::min(x, width)), static_cast<float>(y)};
      points.Append(point);
      fill_points.Append(point);
    }
    // close the area fill down to the bottom corners
    fill_points.Append(winrt::Windows::Foundation::Point{
        static_cast<float>(width), static_cast<float>(height)});
    fill_points.Append(
        winrt::Windows::Foundation::Point{0.0f, static_cast<float>(height)});
    auto const last = points.GetAt(points.Size() - 1);
    Microsoft::UI::Xaml::Controls::Canvas::SetLeft(curve.dot, last.X - 3.5);
    Microsoft::UI::Xaml::Controls::Canvas::SetTop(curve.dot, last.Y - 3.5);
  }
  auto const has_curve = curve.days_held > 1
                             ? Microsoft::UI::Xaml::Visibility::Visible
                             : Microsoft::UI::Xaml::Visibility::Collapsed;
  curve.line.Visibility(has_curve);
  curve.fill.Visibility(has_curve);
  curve.dot.Visibility(has_curve);
}

void MainWindow::UpdateToolbarEnabled() {
  // the detail pane always falls back to a device, so edit/delete are live
  // exactly while a device exists
  bool const has_device = !document_.devices.empty();
  EditButton().IsEnabled(has_device);
  DeleteButton().IsEnabled(has_device);
}

// ---------- toolbar ------------------------------------------------------------

void MainWindow::SortBox_SelectionChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const&) {
  if (SortBox() == nullptr) {
    return;
  }
  auto const index = SortBox().SelectedIndex();
  if (index >= 0) {
    sort_mode_ = index;
    RenderDeviceList();
  }
}

void MainWindow::AddButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  SaveDeviceAsync(false, L"");
}

void MainWindow::EditButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  if (!selected_device_id_.empty()) {
    SaveDeviceAsync(true, selected_device_id_);
  }
}

void MainWindow::DeleteButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  if (!selected_device_id_.empty()) {
    ShowDeleteConfirm(selected_device_id_);
  }
}

void MainWindow::SettingsButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  OpenSettingsDialog();
}

// About box: version line + product line + license + the two links that
// route feedback (website, issue tracker).
winrt::fire_and_forget MainWindow::AboutButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  Strings const& s = strings();
  auto panel = Microsoft::UI::Xaml::Controls::StackPanel();
  panel.Spacing(4);
  auto tagline = Microsoft::UI::Xaml::Controls::TextBlock();
  tagline.Text(s.about_content());
  tagline.TextAlignment(Microsoft::UI::Xaml::TextAlignment::Center);
  tagline.Margin({0, 0, 0, 8});
  auto license = Microsoft::UI::Xaml::Controls::TextBlock();
  license.Text(s.about_license());
  license.TextAlignment(Microsoft::UI::Xaml::TextAlignment::Center);
  license.FontSize(12);
  license.Opacity(0.75);
  auto website = Microsoft::UI::Xaml::Controls::HyperlinkButton();
  website.Content(winrt::box_value(s.about_website()));
  website.NavigateUri(winrt::Windows::Foundation::Uri{L"https://payback.jrtx.site"});
  website.HorizontalAlignment(Microsoft::UI::Xaml::HorizontalAlignment::Center);
  website.Padding({0, 0, 0, 0});
  auto issue = Microsoft::UI::Xaml::Controls::HyperlinkButton();
  issue.Content(winrt::box_value(s.about_report_issue()));
  issue.NavigateUri(winrt::Windows::Foundation::Uri{
      L"https://github.com/turlamai/payback/issues"});
  issue.HorizontalAlignment(Microsoft::UI::Xaml::HorizontalAlignment::Center);
  issue.Padding({0, 0, 0, 0});
  panel.Children().Append(tagline);
  panel.Children().Append(license);
  panel.Children().Append(website);
  panel.Children().Append(issue);

  Microsoft::UI::Xaml::Controls::ContentDialog dialog;
  dialog.Title(winrt::box_value(L"Payback v" +
                                to_utf8_as_wide(std::string(rivet_app::kVersion))));
  dialog.Content(winrt::box_value(panel));
  dialog.CloseButtonText(s.close());
  dialog.XamlRoot(Content().XamlRoot());
  try {
    co_await dialog.ShowAsync();
  } catch (...) {
    // another dialog is already up; the About button can be pressed again
  }
}

// ---------- add / edit / delete ----------------------------------------------

// One form dialog serves both add and edit (update == true).
void MainWindow::SaveDeviceAsync(bool update, std::wstring id) {
  auto existing = std::make_shared<DeviceRow>();
  if (update) {
    bool found = false;
    for (auto const& row : document_.devices) {
      if (row.id == id) {
        existing = std::make_shared<DeviceRow>(row);
        found = true;
      }
    }
    if (!found) {
      return;
    }
  }

  Strings const& s = strings();
  auto panel = Microsoft::UI::Xaml::Controls::StackPanel();
  panel.Spacing(10);
  panel.Width(360);

  auto name_box = Microsoft::UI::Xaml::Controls::TextBox();
  name_box.Header(winrt::box_value(s.name()));
  name_box.Text(existing->name);
  panel.Children().Append(name_box);

  auto icon_box = Microsoft::UI::Xaml::Controls::TextBox();
  icon_box.Header(winrt::box_value(s.icon() + L" (💻📱🎧…)"));
  icon_box.Text(existing->icon);
  panel.Children().Append(icon_box);

  auto category_box = Microsoft::UI::Xaml::Controls::ComboBox();
  category_box.Header(winrt::box_value(s.category()));
  // the prototype's seven display options mapped onto engine values
  // (accessory = keyboard, appliance = coffee); a legacy stored value
  // (watch/camera/gaming) keeps its own entry so a save never silently
  // rewrites it (design/DESIGN.md native-mapping)
  std::vector<std::pair<std::wstring, std::wstring>> const categories = {
      {L"computer", s.category_computer()}, {L"accessory", s.category_accessory()},
      {L"tablet", s.category_tablet()},     {L"audio", s.category_audio()},
      {L"phone", s.category_phone()},       {L"appliance", s.category_appliance()},
      {L"other", s.category_other()}};
  std::vector<std::pair<std::wstring, std::wstring>> options = categories;
  bool const legacy =
      !std::any_of(options.begin(), options.end(),
                   [&](auto const& pair) { return pair.first == existing->category; });
  if (update && legacy) {
    options.push_back({existing->category, category_display_name(existing->category)});
  }
  int selected = -1;
  int index = 0;
  for (auto const& [category_id, category_label] : options) {
    Microsoft::UI::Xaml::Controls::ComboBoxItem item;
    item.Content(winrt::box_value(category_label));
    item.Tag(winrt::box_value(winrt::hstring(category_id)));
    category_box.Items().Append(item);
    if (category_id == existing->category) {
      selected = index;
    }
    ++index;
  }
  if (selected < 0) {
    selected = static_cast<int>(options.size()) - 1;
  }
  category_box.SelectedIndex(selected);
  panel.Children().Append(category_box);

  auto price_box = Microsoft::UI::Xaml::Controls::TextBox();
  price_box.Header(winrt::box_value(s.price() + L" (" + document_.currency + L")"));
  if (update) {
    wchar_t buffer[32];
    std::swprintf(buffer, 32, L"%.2f", existing->price_minor / 100.0);
    price_box.Text(buffer);
  }
  panel.Children().Append(price_box);

  // say why Save refuses the round trip instead of leaving the error to the
  // backend: the hint tracks the field live, and Closing cancels a save
  // that would carry an invalid amount
  auto price_error = Microsoft::UI::Xaml::Controls::TextBlock();
  price_error.Text(s.price_required_hint());
  price_error.FontSize(11);
  price_error.Foreground(Microsoft::UI::Xaml::Media::SolidColorBrush{
      Microsoft::UI::Colors::Red()});
  auto const price_error_visible = [](Microsoft::UI::Xaml::Controls::TextBox const& box) {
    return parse_amount_minor(box.Text()) <= 0
               ? Microsoft::UI::Xaml::Visibility::Visible
               : Microsoft::UI::Xaml::Visibility::Collapsed;
  };
  price_error.Visibility(price_error_visible(price_box));
  panel.Children().Append(price_error);
  // TextChanged is EventHandler<object>: the sender arrives as IInspectable
  // and must be cast back (Toggled, by contrast, ships a typed sender)
  price_box.TextChanged(
      [price_error, price_error_visible](
          winrt::Windows::Foundation::IInspectable const& sender,
          winrt::Windows::Foundation::IInspectable const&) {
        auto const box = sender.as<Microsoft::UI::Xaml::Controls::TextBox>();
        price_error.Visibility(price_error_visible(box));
      });

  auto date_picker = Microsoft::UI::Xaml::Controls::DatePicker();
  date_picker.Header(winrt::box_value(s.purchase_date()));
  // the redesign's date floor is 1900 (design/DESIGN.md, matches the
  // engine's widened validation)
  date_picker.MinYear(parse_date(L"1900-01-01"));
  if (update) {
    date_picker.Date(parse_date(existing->purchase_date));
  }
  panel.Children().Append(date_picker);

  auto willing_toggle = Microsoft::UI::Xaml::Controls::ToggleSwitch();
  willing_toggle.Header(winrt::box_value(s.willing_label()));
  willing_toggle.IsOn(existing->has_willing);
  panel.Children().Append(willing_toggle);

  auto willing_box = Microsoft::UI::Xaml::Controls::TextBox();
  if (update && existing->has_willing) {
    wchar_t buffer[32];
    std::swprintf(buffer, 32, L"%.2f", existing->willing_per_day_minor / 100.0);
    willing_box.Text(buffer);
  }
  panel.Children().Append(willing_box);

  // enabled with a clean amount = set; enabled but empty = not set; enabled
  // with garbage would silently drop the field — surface that before save
  auto willing_error = Microsoft::UI::Xaml::Controls::TextBlock();
  willing_error.Text(s.price_required_hint());
  willing_error.FontSize(11);
  willing_error.Foreground(Microsoft::UI::Xaml::Media::SolidColorBrush{
      Microsoft::UI::Colors::Red()});
  auto const willing_error_visible =
      [](Microsoft::UI::Xaml::Controls::ToggleSwitch const& toggle,
         Microsoft::UI::Xaml::Controls::TextBox const& box) {
        return toggle.IsOn() && !box.Text().empty() &&
                       parse_amount_minor(box.Text()) <= 0
                   ? Microsoft::UI::Xaml::Visibility::Visible
                   : Microsoft::UI::Xaml::Visibility::Collapsed;
      };
  willing_error.Visibility(willing_error_visible(willing_toggle, willing_box));
  panel.Children().Append(willing_error);
  // WinUI 3 projects the classic control events as EventHandler<object>:
  // every sender arrives as IInspectable and is cast back to its control
  willing_toggle.Toggled(
      [willing_box, willing_error, willing_error_visible](
          winrt::Windows::Foundation::IInspectable const& sender,
          winrt::Windows::Foundation::IInspectable const&) {
        auto const toggle =
            sender.as<Microsoft::UI::Xaml::Controls::ToggleSwitch>();
        willing_error.Visibility(willing_error_visible(toggle, willing_box));
      });
  willing_box.TextChanged(
      [willing_toggle, willing_error, willing_error_visible](
          winrt::Windows::Foundation::IInspectable const& sender,
          winrt::Windows::Foundation::IInspectable const&) {
        auto const box = sender.as<Microsoft::UI::Xaml::Controls::TextBox>();
        willing_error.Visibility(
            willing_error_visible(willing_toggle, box));
      });

  auto hint = Microsoft::UI::Xaml::Controls::TextBlock();
  hint.Text(s.willing_hint());
  hint.FontSize(11);
  hint.Opacity(0.65);
  hint.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  panel.Children().Append(hint);

  auto notes_box = Microsoft::UI::Xaml::Controls::TextBox();
  notes_box.Header(winrt::box_value(s.notes()));
  notes_box.Text(existing->notes);
  panel.Children().Append(notes_box);

  // save failures render here, at the form, so the fields survive for a
  // retry — never in the window-level error bar (#24)
  auto form_error = Microsoft::UI::Xaml::Controls::TextBlock();
  form_error.FontSize(11);
  form_error.Foreground(Microsoft::UI::Xaml::Media::SolidColorBrush{
      Microsoft::UI::Colors::Red()});
  form_error.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
  form_error.Visibility(Microsoft::UI::Xaml::Visibility::Collapsed);
  panel.Children().Append(form_error);

  Microsoft::UI::Xaml::Controls::ContentDialog dialog;
  dialog.Title(winrt::box_value(update ? s.edit() : s.add_device()));
  dialog.Content(panel);
  dialog.PrimaryButtonText(s.save());
  dialog.CloseButtonText(s.cancel());
  dialog.DefaultButton(Microsoft::UI::Xaml::Controls::ContentDialogButton::Primary);
  dialog.XamlRoot(Content().XamlRoot());

  // ContentDialog buttons can't be disabled; the close-cancel guard does
  // the state machine instead: an invalid field, a save already in flight
  // and a mid-flight cancel all keep the form open, and the dialog closes
  // only after the backend confirms persistence (#24). Hide() closes it
  // programmatically once the save lands.
  struct FormSaveState {
    bool saving = false;
  };
  auto state = std::make_shared<FormSaveState>();

  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;

  auto const show_form_error = [form_error](std::wstring const& message) {
    form_error.Text(winrt::hstring(message));
    form_error.Visibility(message.empty()
                              ? Microsoft::UI::Xaml::Visibility::Collapsed
                              : Microsoft::UI::Xaml::Visibility::Visible);
  };

  dialog.Closing(
      [state, dialog, dispatcher, weak, backend, update, id, name_box,
       icon_box, category_box, price_box, date_picker, willing_toggle,
       willing_box, notes_box, form_error, show_form_error, existing](
          Microsoft::UI::Xaml::Controls::ContentDialog const&,
          Microsoft::UI::Xaml::Controls::ContentDialogClosingEventArgs const&
              args) {
        if (args.Result() !=
            Microsoft::UI::Xaml::Controls::ContentDialogResult::Primary) {
          // mid-flight cancel would leave the outcome unknown; wait it out
          if (state->saving) {
            args.Cancel(true);
          }
          return;
        }
        if (state->saving) {
          args.Cancel(true);  // double Save must not create a second record
          return;
        }

        auto const category = [&]() -> std::wstring {
          auto item = category_box.SelectedItem();
          if (item) {
            auto const value = winrt::unbox_value<winrt::hstring>(
                item.as<Microsoft::UI::Xaml::Controls::ComboBoxItem>().Tag());
            return std::wstring(value.c_str());
          }
          return L"other";
        }();
        auto const price_minor = parse_amount_minor(price_box.Text());
        auto const willing_minor = parse_amount_minor(willing_box.Text());
        bool const price_bad = price_minor <= 0;
        bool const willing_bad =
            willing_toggle.IsOn() && !willing_box.Text().empty() &&
            willing_minor <= 0;
        if (price_bad || willing_bad) {
          args.Cancel(true);
          show_form_error(L"");
          return;
        }

        // stay open while the save runs; fields stay exactly as typed so
        // a failure can be retried in place
        state->saving = true;
        args.Cancel(true);
        form_error.Visibility(Microsoft::UI::Xaml::Visibility::Collapsed);

        std::wstring json = L"{";
        json += L"\"name\":" +
                JsonValue::CreateStringValue(name_box.Text()).Stringify() +
                L",";
        json += L"\"icon\":" +
                JsonValue::CreateStringValue(icon_box.Text()).Stringify() +
                L",";
        json += L"\"category\":" +
                JsonValue::CreateStringValue(category).Stringify() + L",";
        json += L"\"priceMinor\":" + std::to_wstring(price_minor) + L",";
        json += L"\"currency\":" +
                JsonValue::CreateStringValue(existing->currency).Stringify() +
                L",";
        json += L"\"purchaseDate\":" +
                JsonValue::CreateStringValue(format_date(date_picker.Date()))
                    .Stringify() +
                L",";
        if (willing_toggle.IsOn() && willing_minor > 0) {
          json += L"\"willingPerDayMinor\":" + std::to_wstring(willing_minor) +
                  L",";
        } else {
          json += L"\"willingPerDayMinor\":null,";
        }
        json += L"\"notes\":" +
                JsonValue::CreateStringValue(notes_box.Text()).Stringify();
        if (update) {
          json += L",\"id\":" +
                  JsonValue::CreateStringValue(id).Stringify();
        }
        json += L"}";

        auto const payload = to_bytes(json);
        try {
          rivet_app::API api(*backend);
          auto const callbackDispatcher = dispatcher;
          auto handler = [state, dialog, callbackDispatcher, weak,
                          form_error, show_form_error](
                             rivet_app::Result<rivet::Bytes> result) {
            std::string failure;
            try {
              (void)result.get();
            } catch (std::exception const& e) {
              failure = e.what();
            }
            callbackDispatcher.TryEnqueue(
                [state, dialog, weak, failure = std::move(failure),
                 form_error, show_form_error] {
                  if (failure.empty()) {
                    if (auto window = weak.get()) {
                      window->LoadAllAsync();
                    }
                    state->saving = false;  // before Hide(): Closing must allow it
                    dialog.Hide();
                    return;
                  }
                  // keep the form open with its fields; Save acts as Retry
                  state->saving = false;
                  show_form_error(
                      std::wstring(winrt::to_hstring(failure).c_str()));
                });
          };
          if (update) {
            (void)api.update_device_async(payload, handler);
          } else {
            (void)api.add_device_async(payload, handler);
          }
        } catch (std::exception const& e) {
          state->saving = false;
          show_form_error(std::wstring(winrt::to_hstring(e.what()).c_str()));
          args.Cancel(true);
        }
      });

  (void)dialog.ShowAsync();
}

void MainWindow::DeleteDeviceAsync(std::wstring id) {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  try {
    rivet_app::API api(*backend);
    (void)api.delete_device_async(
        wide_to_utf8(id),
        [dispatcher, weak, id](rivet_app::Result<void> result) {
          std::string failure;
          try {
            result.get();
          } catch (std::exception const& e) {
            failure = e.what();
          }
          dispatcher.TryEnqueue([weak, failure = std::move(failure), id] {
            if (auto window = weak.get()) {
              if (!failure.empty()) {
                window->SetErrorUi(failure);
              } else {
                // delete is a tombstone: the toast's 撤销 can bring it back
                // (docs/data-format.md "Trash")
                window->last_deleted_id_ = std::wstring(id.c_str());
                window->ShowUndoToast();
                window->LoadAllAsync();
              }
            }
          });
        });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

void MainWindow::ShowDeleteConfirm(std::wstring const& id) {
  Strings const& s = strings();
  Microsoft::UI::Xaml::Controls::ContentDialog dialog;
  dialog.Title(winrt::box_value(s.delete_confirm_title()));
  dialog.Content(winrt::box_value(winrt::hstring(s.delete_confirm_text())));
  dialog.PrimaryButtonText(s.move_to_deleted());
  dialog.CloseButtonText(s.keep_device());
  dialog.DefaultButton(Microsoft::UI::Xaml::Controls::ContentDialogButton::Close);
  dialog.XamlRoot(Content().XamlRoot());

  auto const weak = get_weak();
  auto operation = dialog.ShowAsync();
  operation.Completed([weak, id](auto const& async, auto&&) {
    if (auto window = weak.get()) {
      if (async.GetResults() ==
          Microsoft::UI::Xaml::Controls::ContentDialogResult::Primary) {
        window->DeleteDeviceAsync(id);
      }
    }
  });
}


// ---------- trash, undo and backup (2026-11 redesign) -------------------------

// The delete toast reuses the status InfoBar: message + 撤销, ten seconds,
// then the row gives itself back to the list.
void MainWindow::ShowUndoToast() {
  Strings const& s = strings();
  StatusBar().IsOpen(true);
  StatusBar().Severity(Microsoft::UI::Xaml::Controls::InfoBarSeverity::Success);
  StatusMessage().Text(s.toast_deleted());
  UndoButton().Visibility(Microsoft::UI::Xaml::Visibility::Visible);
  undo_timer_ = std::make_shared<Microsoft::UI::Xaml::DispatcherTimer>();
  undo_timer_->Interval(std::chrono::seconds(10));
  auto const weak = get_weak();
  undo_timer_->Tick([weak](auto const& sender, auto const&) {
    if (auto window = weak.get()) {
      window->DismissUndoToast();
    }
    sender.as<Microsoft::UI::Xaml::DispatcherTimer>().Stop();
  });
  undo_timer_->Start();
}

void MainWindow::DismissUndoToast() {
  if (UndoButton()) {
    UndoButton().Visibility(Microsoft::UI::Xaml::Visibility::Collapsed);
  }
  if (StatusBar().Severity() ==
      Microsoft::UI::Xaml::Controls::InfoBarSeverity::Success) {
    StatusBar().IsOpen(false);
  }
  last_deleted_id_.clear();
  if (undo_timer_) {
    undo_timer_->Stop();
    undo_timer_ = nullptr;
  }
}

void MainWindow::UndoButton_Click(
    winrt::Windows::Foundation::IInspectable const&,
    Microsoft::UI::Xaml::RoutedEventArgs const&) {
  if (!last_deleted_id_.empty()) {
    std::wstring const id = last_deleted_id_;
    DismissUndoToast();
    RestoreDeviceAsync(id, true);
  }
}

// restore-device clears the tombstone with a fresh LWW claim; the record
// returns with its purchase details and goal intact
void MainWindow::RestoreDeviceAsync(std::wstring id, bool follow_selection) {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  try {
    rivet_app::API api(*backend);
    (void)api.restore_device_async(
        wide_to_utf8(id),
        [dispatcher, weak, id, follow_selection](
            rivet_app::Result<rivet::Bytes> result) {
          std::string failure;
          try {
            (void)result.get();
          } catch (std::exception const& e) {
            failure = e.what();
          }
          dispatcher.TryEnqueue([weak, failure = std::move(failure), id,
                                 follow_selection] {
            if (auto window = weak.get()) {
              if (!failure.empty()) {
                window->SetErrorUi(failure);
                return;
              }
              if (follow_selection) {
                window->selected_device_id_ = std::wstring(id.c_str());
              }
              window->ShowSuccess(strings().device_restored());
              window->LoadAllAsync();
            }
          });
        });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

void MainWindow::LoadTrashAsync(bool show_after) {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  try {
    rivet_app::API api(*backend);
    (void)api.trash_list_async([dispatcher, weak](
                                   rivet_app::Result<rivet::Bytes> result) {
      std::vector<std::uint8_t> payload;
      std::string failure;
      try {
        payload = result.get();
      } catch (std::exception const& e) {
        failure = e.what();
      }
      dispatcher.TryEnqueue([weak, payload = std::move(payload),
                             failure = std::move(failure), show_after] {
        if (auto window = weak.get()) {
          if (!failure.empty()) {
            window->SetErrorUi(failure);
          } else {
            window->ApplyTrashPayload(payload);
            if (show_after) {
              window->ShowTrashDialog();
            }
          }
        }
      });
    });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

void MainWindow::ApplyTrashPayload(std::vector<std::uint8_t> const& payload) {
  trash_.clear();
  auto const wide = to_utf8_as_wide(std::string(payload.begin(), payload.end()));
  auto parsed = JsonObject::Parse(wide);
  auto const entries = field(parsed, L"trash");
  if (entries.ValueType() == Windows::Data::Json::JsonValueType::Array) {
    for (auto const& item : entries.GetArray()) {
      DeviceRow row;
      row.id = as_string(field(item, L"id"));
      row.name = as_string(field(item, L"name"));
      row.category = as_string(field(item, L"category"));
      row.price_minor = as_int(field(item, L"priceMinor"));
      row.currency = as_string(field(item, L"currency"), document_.currency);
      row.purchase_date = as_string(field(item, L"purchaseDate"));
      trash_.push_back(row);
    }
  }
}

// 最近删除 dialog: restorable records, oldest 50 shown like the prototype;
// restoring keeps ids and goals intact and there is no purge
winrt::fire_and_forget MainWindow::ShowTrashDialog() {
  Strings const& s = strings();
  auto panel = Microsoft::UI::Xaml::Controls::StackPanel();
  panel.Spacing(8);
  panel.Width(460);
  panel.Children().Append([]() {
    Microsoft::UI::Xaml::Controls::TextBlock intro;
    intro.Text(strings().trash_intro());
    intro.FontSize(12);
    intro.Opacity(0.7);
    intro.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    return intro;
  }());

  auto const weak = get_weak();
  std::size_t const shown = std::min<std::size_t>(trash_.size(), 50);
  for (std::size_t i = 0; i < shown; ++i) {
    auto const& entry = trash_[i];
    auto row_grid = Microsoft::UI::Xaml::Controls::Grid();
    row_grid.ColumnDefinitions().Append(star_column());
    row_grid.ColumnDefinitions().Append(auto_column());
    auto info = Microsoft::UI::Xaml::Controls::StackPanel();
    info.Spacing(2);
    auto name = Microsoft::UI::Xaml::Controls::TextBlock();
    name.Text(entry.name);
    name.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
    name.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    info.Children().Append(name);
    auto facts = Microsoft::UI::Xaml::Controls::TextBlock();
    facts.Text(money(static_cast<double>(entry.price_minor), entry.currency) +
               L" · " + entry.purchase_date);
    facts.FontSize(12);
    facts.Opacity(0.7);
    info.Children().Append(facts);
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(info, 0);
    row_grid.Children().Append(info);
    auto restore = Microsoft::UI::Xaml::Controls::Button();
    restore.Content(winrt::box_value(winrt::hstring(s.restore_button())));
    Microsoft::UI::Xaml::Controls::Grid::SetColumn(restore, 1);
    restore.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Center);
    std::wstring const id = entry.id;
    restore.Click([weak, id](auto const&, auto const&) {
      if (auto window = weak.get()) {
        window->RestoreDeviceAsync(id, false);
      }
    });
    row_grid.Children().Append(restore);
    panel.Children().Append(row_grid);
  }
  if (trash_.empty()) {
    auto empty = Microsoft::UI::Xaml::Controls::TextBlock();
    empty.Text(s.trash_empty());
    empty.Opacity(0.7);
    panel.Children().Append(empty);
  }

  Microsoft::UI::Xaml::Controls::ContentDialog dialog;
  dialog.Title(winrt::box_value(s.trash_title()));
  dialog.Content(winrt::box_value(panel));
  dialog.CloseButtonText(s.close());
  dialog.XamlRoot(Content().XamlRoot());
  try {
    co_await dialog.ShowAsync();
  } catch (...) {
    // another dialog already open
  }
}

void MainWindow::ExportBackupAsync() {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  // the save picker is its own OS window: drop the settings dialog first
  if (settings_dialog_operation_) {
    settings_dialog_operation_->Cancel();
    settings_dialog_operation_ = nullptr;
  }
  try {
    winrt::Windows::Storage::Pickers::FileSavePicker picker;
    picker.SuggestedStartLocation(
        winrt::Windows::Storage::Pickers::PickerLocationId::DocumentsLibrary);
    picker.SuggestedFileName(L"payback-backup");
    picker.FileTypeChoices().Insert(L"JSON", std::vector<winrt::hstring>{L".json"});
    auto const initialize_with_window = picker.as<::IInitializeWithWindow>();
    auto hwnd = ::GetActiveWindow();
    if (hwnd == nullptr) {
      hwnd = ::GetForegroundWindow();
    }
    initialize_with_window->Initialize(hwnd);

    auto operation = picker.PickSaveFileAsync();
    operation.Completed([dispatcher, weak, backend](auto const& async, auto&&) {
      winrt::Windows::Storage::StorageFile file{nullptr};
      try {
        file = async.GetResults();
      } catch (...) {
      }
      if (!file) {
        return;
      }
      try {
        rivet_app::API api(*backend);
        (void)api.backup_export_async(
            [dispatcher, weak, file](rivet_app::Result<rivet::Bytes> result) {
              std::vector<std::uint8_t> payload;
              std::string failure;
              try {
                payload = result.get();
              } catch (std::exception const& e) {
                failure = e.what();
              }
              dispatcher.TryEnqueue([weak, file, payload = std::move(payload),
                                     failure = std::move(failure)]() mutable {
                if (auto window = weak.get()) {
                  if (!failure.empty()) {
                    window->SetErrorUi(failure);
                    return;
                  }
                  auto const written =
                      winrt::Windows::Storage::FileIO::WriteBytesAsync(
                          file, payload);
                  written.Completed([weak](auto const& write_async, auto&&) {
                    try {
                      (void)write_async.GetResults();
                    } catch (...) {
                    }
                  });
                }
              });
            });
      } catch (std::exception const& e) {
        dispatcher.TryEnqueue([weak, message = e.what()] {
          if (auto window = weak.get()) {
            window->SetErrorUi(message);
          }
        });
      }
    });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

void MainWindow::RestoreBackupAsync() {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  if (settings_dialog_operation_) {
    settings_dialog_operation_->Cancel();
    settings_dialog_operation_ = nullptr;
  }
  try {
    winrt::Windows::Storage::Pickers::FileOpenPicker picker;
    picker.FileTypeFilter().Append(L".json");
    auto const initialize_with_window = picker.as<::IInitializeWithWindow>();
    auto hwnd = ::GetActiveWindow();
    if (hwnd == nullptr) {
      hwnd = ::GetForegroundWindow();
    }
    initialize_with_window->Initialize(hwnd);

    auto operation = picker.PickSingleFileAsync();
    operation.Completed([dispatcher, weak, backend](auto const& async, auto&&) {
      winrt::Windows::Storage::StorageFile file{nullptr};
      try {
        file = async.GetResults();
      } catch (...) {
      }
      if (!file) {
        return;
      }
      auto read = winrt::Windows::Storage::FileIO::ReadBufferAsync(file);
      read.Completed([dispatcher, weak, backend](auto const& read_async, auto&&) {
        std::vector<std::uint8_t> payload;
        std::string failure;
        try {
          auto buffer = read_async.GetResults();
          auto reader =
              winrt::Windows::Storage::Streams::DataReader::FromBuffer(buffer);
          reader.UnconsumedBufferLength();
          payload.resize(buffer.Length());
          reader.ReadBytes(payload);
        } catch (std::exception const& e) {
          failure = e.what();
        }
        if (!failure.empty()) {
          dispatcher.TryEnqueue([weak, message = failure] {
            if (auto window = weak.get()) {
              window->SetErrorUi(message);
            }
          });
          return;
        }
        try {
          rivet_app::API api(*backend);
          (void)api.backup_validate_async(
              payload,
              [dispatcher, weak, payload = std::move(payload)](
                  rivet_app::Result<rivet::Bytes> result) mutable {
                std::vector<std::uint8_t> validated;
                std::string validate_failure;
                try {
                  validated = result.get();
                } catch (std::exception const& e) {
                  validate_failure = e.what();
                }
                dispatcher.TryEnqueue(
                    [weak, payload = std::move(payload),
                     validated = std::move(validated),
                     failure = std::move(validate_failure)]() mutable {
                      if (auto window = weak.get()) {
                        window->ShowRestoreReview(payload, validated, failure);
                      }
                    });
              });
        } catch (std::exception const& e) {
          dispatcher.TryEnqueue([weak, message = e.what()] {
            if (auto window = weak.get()) {
              window->SetErrorUi(message);
            }
          });
        }
      });
    });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

// validate → review → explicit confirm; validation failures never touch data
void MainWindow::ShowRestoreReview(std::vector<std::uint8_t> const& payload,
                                   std::vector<std::uint8_t> const& validated,
                                   std::string const& failure) {
  Strings const& s = strings();
  auto panel = Microsoft::UI::Xaml::Controls::StackPanel();
  panel.Spacing(10);
  panel.Width(460);

  if (!failure.empty()) {
    auto error = Microsoft::UI::Xaml::Controls::TextBlock();
    error.Text(s.backup_invalid());
    error.Foreground(destructive_brush());
    error.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    panel.Children().Append(error);
    auto detail = Microsoft::UI::Xaml::Controls::TextBlock();
    detail.Text(winrt::to_hstring(failure));
    detail.FontSize(12);
    detail.Opacity(0.75);
    detail.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    panel.Children().Append(detail);
  } else {
    auto const wide =
        to_utf8_as_wide(std::string(validated.begin(), validated.end()));
    auto parsed = JsonObject::Parse(wide);
    int const replace_count = static_cast<int>(as_int(field(parsed, L"replaceCount")));
    int const import_count = static_cast<int>(as_int(field(parsed, L"importCount")));
    int const trash_count = static_cast<int>(as_int(field(parsed, L"trashCount")));

    auto summary = Microsoft::UI::Xaml::Controls::StackPanel();
    summary.Spacing(4);
    auto add_stat = [&](int const value, std::wstring const& label) {
      auto row_grid = Microsoft::UI::Xaml::Controls::Grid();
      row_grid.ColumnDefinitions().Append(pixel_column(56));
      row_grid.ColumnDefinitions().Append(star_column());
      auto number = Microsoft::UI::Xaml::Controls::TextBlock();
      number.Text(std::to_wstring(value));
      number.FontSize(24);
      number.FontWeight(Microsoft::UI::Text::FontWeights::SemiBold());
      Microsoft::UI::Xaml::Controls::Grid::SetColumn(number, 0);
      row_grid.Children().Append(number);
      auto caption = Microsoft::UI::Xaml::Controls::TextBlock();
      caption.Text(label);
      caption.FontSize(13);
      caption.Opacity(0.75);
      caption.VerticalAlignment(Microsoft::UI::Xaml::VerticalAlignment::Bottom);
      Microsoft::UI::Xaml::Controls::Grid::SetColumn(caption, 1);
      row_grid.Children().Append(caption);
      summary.Children().Append(row_grid);
    };
    add_stat(replace_count, s.restore_replaced_label());
    add_stat(import_count, s.restore_imported_label());
    add_stat(trash_count, s.restore_trash_label());
    panel.Children().Append(summary);

    auto note = Microsoft::UI::Xaml::Controls::TextBlock();
    note.Text(s.restore_prefs_note());
    note.FontSize(12);
    note.Opacity(0.75);
    note.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    panel.Children().Append(note);
    auto warning = Microsoft::UI::Xaml::Controls::TextBlock();
    warning.Text(s.restore_warning());
    warning.FontSize(12);
    warning.Foreground(destructive_brush());
    warning.TextWrapping(Microsoft::UI::Xaml::TextWrapping::Wrap);
    panel.Children().Append(warning);
  }

  Microsoft::UI::Xaml::Controls::ContentDialog dialog;
  dialog.Title(winrt::box_value(s.restore_review_title()));
  dialog.Content(winrt::box_value(panel));
  dialog.PrimaryButtonText(s.restore_confirm());
  dialog.CloseButtonText(s.cancel());
  dialog.DefaultButton(Microsoft::UI::Xaml::Controls::ContentDialogButton::Primary);
  dialog.XamlRoot(Content().XamlRoot());
  if (!failure.empty()) {
    dialog.DefaultButton(Microsoft::UI::Xaml::Controls::ContentDialogButton::Close);
  }

  auto const weak = get_weak();
  auto operation = dialog.ShowAsync();
  operation.Completed([weak, payload, failure](auto const& async, auto&&) {
    if (failure.empty()) {
      if (async.GetResults() ==
          Microsoft::UI::Xaml::Controls::ContentDialogResult::Primary) {
        if (auto window = weak.get()) {
          window->ConfirmRestoreAsync(payload);
        }
      }
    }
  });
}

void MainWindow::ConfirmRestoreAsync(std::vector<std::uint8_t> const& payload) {
  auto const dispatcher = DispatcherQueue();
  auto const weak = get_weak();
  auto backend = backend_;
  if (backend == nullptr) {
    return;
  }
  try {
    rivet_app::API api(*backend);
    (void)api.backup_restore_async(
        payload, [dispatcher, weak](rivet_app::Result<rivet::Bytes> result) {
          std::string failure;
          try {
            (void)result.get();
          } catch (std::exception const& e) {
            failure = e.what();
          }
          dispatcher.TryEnqueue([weak, failure = std::move(failure)] {
            if (auto window = weak.get()) {
              if (!failure.empty()) {
                window->SetErrorUi(failure);
                return;
              }
              window->last_deleted_id_.clear();
              window->ShowSuccess(strings().backup_restored());
              window->LoadAllAsync();
            }
          });
        });
  } catch (std::exception const& e) {
    SetErrorUi(e.what());
  }
}

// ---------- display arithmetic (engine-derived values only) --------------------

std::int64_t MainWindow::days_between(std::wstring const& from,
                                      std::wstring const& to) const {
  auto const parse = [](std::wstring const& text) -> std::int64_t {
    if (text.size() < 10) {
      return 0;
    }
    auto const digit = [](wchar_t const c) { return c - L'0'; };
    std::int64_t const y = digit(text[0]) * 1000 + digit(text[1]) * 100 +
                           digit(text[2]) * 10 + digit(text[3]);
    std::int64_t const m = digit(text[5]) * 10 + digit(text[6]);
    std::int64_t const d = digit(text[8]) * 10 + digit(text[9]);
    // Howard Hinnant's days_from_civil, same algorithm as the engine
    std::int64_t const yy = m <= 2 ? y - 1 : y;
    std::int64_t const mm = m <= 2 ? m + 9 : m - 3;
    std::int64_t const era = yy / 400;
    std::int64_t const yoe = yy - era * 400;
    std::int64_t const doy = (153 * mm + 2) / 5 + d - 1;
    std::int64_t const doe = 365 * yoe + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
  };
  return parse(to) - parse(from);
}

// remaining days to the goal: ⌈price/willing⌉ − held, floored at zero —
// the engine's paybackEta date minus the days already held
std::int64_t MainWindow::remaining_goal_days(DeviceRow const& row) const {
  if (!row.has_willing || row.computed.payback_eta.empty()) {
    return 0;
  }
  auto const total =
      days_between(row.purchase_date, row.computed.payback_eta) + 1;
  return std::max<std::int64_t>(total - row.computed.days_held, 0);
}

std::wstring MainWindow::format_days(std::int64_t days) const {
  std::wstring digits = std::to_wstring(days);
  std::wstring grouped;
  int const first_group = static_cast<int>(digits.size() % 3);
  std::size_t index = 0;
  if (first_group > 0) {
    grouped.append(digits, 0, static_cast<std::size_t>(first_group));
    index = static_cast<std::size_t>(first_group);
    if (index < digits.size()) {
      grouped += L',';
    }
  }
  for (; index < digits.size(); index += 3) {
    grouped.append(digits, index, 3);
    if (index + 3 < digits.size()) {
      grouped += L',';
    }
  }
  return grouped;
}

}  // namespace winrt::RivetHost::implementation
