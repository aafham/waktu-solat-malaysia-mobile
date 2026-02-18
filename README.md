# JagaSolat (Flutter)

Tagline: `Jangan dok tinggai solat.`

Aplikasi mudah alih untuk bantu pengguna Malaysia jaga amalan harian dengan 3 fokus utama:
- Waktu Solat
- Qiblat
- Zikir

## Status UI Terkini
Kemaskini terkini membawa gaya visual gelap yang konsisten di semua page:
- Palette navy gelap + kad biru-kelabu rounded.
- Splash screen Android + Flutter yang konsisten.
- `Settings` dirombak kepada `progressive disclosure` (main page ringkas + subpages detail).
- Page `Zikir` dikemas dari segi hierarchy, kontras, progress ring, dan milestone.
- Page `Qiblat` dikemas dengan struktur status + kompas + panduan kalibrasi yang lebih jelas.

## Fokus Utama Aplikasi
- `Waktu Solat`: waktu harian ikut zon Malaysia, countdown ke waktu seterusnya, check-in solat harian.
- `Qiblat`: kompas qiblat dengan bacaan darjah, indikator ketepatan, status aktif/henti, dan panduan kalibrasi.
- `Zikir`: tasbih digital dengan sasaran pusingan (33/99/100), batch tambah, auto reset harian, statistik harian/mingguan/streak.

## Navigasi Semasa
Bottom navigation:
- `Times`
- `Qibla`
- `Tasbih`
- `Settings`

## Ciri Tambahan
- Sokongan bahasa BM/EN konsisten (Material + app labels ikut language setting).
- Nama waktu solat kekal istilah standard Malaysia (`Imsak`, `Subuh`, `Zohor`, `Asar`, `Maghrib`, `Isyak`).
- Lokasi automatik (GPS) + zon manual.
- Fallback permission lokasi: jika lokasi ditolak, app paksa aliran pilih zon manual (search + recent).
- Notifikasi waktu solat (tetapan per waktu + lead time + bunyi azan global/per-waktu + `respect silent mode`).
- Travel mode auto tukar zon.
- Reminder puasa (`Ramadhan`, `Isnin/Khamis`, `Ayyamul Bidh`).
- Hijri offset setting `-2..+2` (diguna pada preview puasa dan logik peringatan puasa).
- Mod kontras tinggi dan saiz teks boleh laras.
- Tetapan kiraan solat: calculation method, Asar method, high latitude rule, dan manual minute adjustment per waktu.
- Action reset semua manual minute adjustments dengan confirmation.
- Tasbih settings: sasaran `33/99/100/custom`, auto reset harian, reset kiraan, statistik ringkas.
- Prayer History 7 hari (ringkasan done/target per hari).
- Onboarding setup awal (notifikasi + lokasi automatik).
- Simpanan setempat (`SharedPreferences`) untuk fallback data.
- Android home widget 3 saiz dengan paparan berbeza:
  - `2x1` Next Prayer Compact
  - `2x2` Next Prayer + Context
  - `3x2` Today Progress
- Widget ikut bahasa sistem telefon (BM/EN) untuk label UI.
- Countdown widget dipaparkan dalam perkataan penuh (`jam/minit` atau `hour/minute`), bukan format ringkas `j/m`.
- Auto-retry fetch data bila gagal + refresh semula bila app kembali aktif.

## Prasyarat
- Flutter SDK
- Android Studio + Android SDK
- Peranti Android fizikal atau emulator

Semak setup:
```bash
flutter doctor
```

## Quick Start
Jalankan dari root projek:
```bash
flutter pub get
flutter run
```

## Ujian & Analisis
```bash
flutter test
flutter analyze --no-pub
```

## Build APK
```bash
flutter build apk --release
```

Output:
- `build/app/outputs/flutter-apk/app-release.apk`

## Konfigurasi Android
Fail: `android/app/src/main/AndroidManifest.xml`

Kebenaran minimum:
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

## Launcher Icon Android
Ikon app menggunakan adaptive icon (Option A minimalist: navy matte + simbol mihrab kuning).

Fail penting:
- `android/app/src/main/AndroidManifest.xml` (`android:icon` + `android:roundIcon`)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (legacy)
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` (adaptive foreground)
- `android/app/src/main/res/mipmap-*/ic_launcher_background.png` (adaptive background)

## Struktur Kod Ringkas
- `lib/main.dart` - inisialisasi app, tema global, splash, navigasi bawah.
- `lib/state/app_controller.dart` - state utama dan aliran data.
- `lib/features/home/home_page.dart` - skrin Waktu Solat (hero, countdown, check-in, freshness pill, CTA history).
- `lib/features/home/history_page.dart` - ringkasan sejarah solat 7 hari.
- `lib/features/qibla/qibla_page.dart` - skrin Qiblat + indikator ketepatan.
- `lib/features/tasbih/tasbih_page.dart` - skrin Zikir + progress ring/milestone.
- `lib/features/settings/settings_page.dart` - settings main + subpages (`Notifications`, `Prayer Times`, `Prayer Calculation`, `Appearance`, `Fasting`, `Tasbih`, `About`).
- `lib/features/settings/hijri_offset_setting.dart` - komponen offset Hijri `-2..+2`.
- `lib/l10n/app_localizations.dart` - localization key map BM/EN (runtime).
- `lib/features/onboarding/onboarding_page.dart` - onboarding + setup awal.
- `lib/features/monthly/monthly_page.dart` - jadual bulanan + eksport.
- `lib/services/prayer_service.dart` - API waktu solat, parser, cache.
- `lib/services/prayer_calculation_service.dart` - kiraan waktu solat tempatan (astronomi) untuk fallback/override preference.
- `lib/services/location_service.dart` - GPS dan permission.
- `lib/services/notification_service.dart` - jadual notifikasi + lead time.
- `lib/services/qibla_service.dart` - kiraan arah kiblat.
- `lib/services/tasbih_store.dart` - simpanan kiraan/tetapan/language + settings tambahan (silent mode, calculation prefs, manual adjustments).
- `lib/services/widget_update_service.dart` - sinkron data ke Android Home Widget (`home_widget`).

## API Digunakan
- `https://solat.my/api/locations`
- `https://solat.my/api/daily/{ZONE_CODE}`
- `https://solat.my/api/monthly/{ZONE_CODE}`

## Nota Teknikal
- Locale runtime: `ms_MY` atau `en_US` ikut pilihan pengguna.
- Timezone notifikasi: `Asia/Kuala_Lumpur`.
- Refresh automatik bila hari bertukar.
- Data zon/waktu disimpan setempat untuk kegunaan offline sementara.
- Auto retry fetch data (maksimum 3 cubaan berturutan).
- `Prayer calculation method / asar / high latitude` kini disimpan sebagai preference pengguna (UI + persistence) dan mempengaruhi kiraan tempatan.
- `Manual minute adjustments` diaplikasikan pada paparan waktu harian dan notifikasi terjadual.
- Bila API harian gagal, app fallback ke `local prayer calculation` berdasarkan zon aktif + preference pengguna.
- Android widget update flow:
  - simpan data widget melalui `home_widget` keys (utama):
    - `nextName`
    - `nextTime`
    - `nextCountdown`
    - `nextSubtitle`
    - `locationLabel`
    - `liveLabel`
    - `todayDone`
    - `streakText`
    - `currentName`
    - `currentTime`
    - `remainingCount` (optional)
  - deep link widget ke Times: `myapp://times`
  - periodic refresh native guna `WorkManager` setiap ~15 min (best-effort)

## Android Home Widget
Implementasi Android AppWidget (3 provider, 3 saiz):
- `NextPrayerSmallWidgetProvider` -> `2x1` compact
- `TasbihWidgetProvider` -> `2x2` next + context
- `NextPrayerWidgetProvider` -> `3x2` today progress

Fail Android utama:
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/NextPrayerWidgetProvider.kt`
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/NextPrayerSmallWidgetProvider.kt`
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/TasbihWidgetProvider.kt`
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/NextPrayerWidgetUpdater.kt`
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/WidgetRefreshWorker.kt`
- `android/app/src/main/kotlin/com/example/waktu_solat_malaysia_mobile/WidgetWorkScheduler.kt`

Layout widget:
- `android/app/src/main/res/layout/widget_2x1_compact.xml`
- `android/app/src/main/res/layout/widget_2x2_next_context.xml`
- `android/app/src/main/res/layout/widget_3x2_today_progress.xml`

Konfigurasi size + preview:
- `android/app/src/main/res/xml/next_prayer_widget_small_info.xml`
- `android/app/src/main/res/xml/tasbih_widget_info.xml`
- `android/app/src/main/res/xml/next_prayer_widget_medium_info.xml`
- `android/app/src/main/res/drawable-nodpi/preview_widget_2x1.png`
- `android/app/src/main/res/drawable-nodpi/preview_widget_2x2.png`
- `android/app/src/main/res/drawable-nodpi/preview_widget_3x2.png`

Resource theme widget:
- `android/app/src/main/res/values/colors.xml`
- `android/app/src/main/res/drawable/widget_bg.xml`
- `android/app/src/main/res/drawable/widget_surface.xml`

Quick test widget:
1. `flutter clean`
2. `flutter pub get`
3. `flutter run`
4. Tambah widget dari launcher (`2x1`, `2x2`, `3x2`) dan sahkan setiap satu paparan berbeza.
5. Tap widget untuk buka app terus ke tab `Times`.

## Troubleshooting Ringkas
- `flutter`/`dart` tidak dijumpai: semak PATH dan restart terminal.
- Notifikasi tidak keluar: semak permission notifikasi dan battery optimization.
- Kompas tidak stabil: buat kalibrasi sensor (gerakan angka 8).
- Lokasi gagal: aktifkan GPS atau guna zon manual.
- Data lambat/tiada: tarik ke bawah untuk muat semula.
- `MissingPluginException(saveWidgetData on channel home_widget)`:
  - stop app penuh (jangan hot-restart sahaja),
  - jalankan `flutter clean && flutter pub get && flutter run`,
  - jika masih berlaku, uninstall app dan install semula.
- Widget `Can't load widget`:
  - buang widget lama dari homescreen, tambah semula widget baru,
  - pastikan build terbaru telah di-install penuh (bukan hot reload sahaja),
  - jika masih berlaku, restart launcher/peranti untuk clear cache host widget.

## Log Patch Terkini (Rujukan Next)
Latest update (17 Feb 2026 - Android Home Widget Patch):
- Tambah Android Home Screen widget baharu:
  - `NextPrayerSmall` (2x1)
  - `NextPrayerMedium` (4x2)
- Theme widget ikut app (dark matte + surface gelap + accent kuning).
- Data widget kini disinkron dari Flutter melalui `home_widget` (`WidgetUpdateService`).
- Subtitle logic widget:
  - jika next = `Imsak` -> `Before Subuh begins`
  - selain itu -> `Until <NextPrayerName> begins`
- Tap widget buka app terus ke `Times` melalui deep link `myapp://times`.
- Tambah periodic native refresh countdown guna `WorkManager` (15 min best-effort).
- Tambah fail-safe handling untuk `MissingPluginException` pada widget update (app tidak crash).
- Validation:
  - `flutter analyze` lulus,
  - `flutter test` lulus,
  - `:app:compileDebugKotlin` lulus.

Latest update (17 Feb 2026 - Final Polish & Completeness Patch):
- i18n diperkemas:
  - tambah `flutter_localizations` delegate di `MaterialApp`,
  - tambah localization key map (`lib/l10n/app_localizations.dart`) untuk label utama termasuk `Times/Qibla/Tasbih/Settings`,
  - hardcoded strings kritikal diganti (contoh `Before Subuh begins`, `Tap to add`, `Details`).
- Times screen polish:
  - CTA `Snooze 5 min` ditukar ke `TextButton.icon`,
  - caption countdown diperkemas sebagai teks sekunder,
  - next prayer resolver diperkukuh (sort + fallback next day).
- Settings completeness:
  - About page ditambah `version`, `build`, `data source`, `privacy`, `feedback`.
  - Prayer Calculation ada action `Reset all adjustments` + confirmation dialog.
  - Prayer Times ada fallback permission lokasi: bila denied/detect off, zone picker manual dipaparkan sebagai aliran wajib (searchable + recent).
- Fungsi must-have ditambah:
  - `Permission onboarding/fallback` untuk lokasi ditolak,
  - `Prayer History` screen untuk 7 hari terakhir,
  - `Hijri offset` setting `-2..+2` dengan aplikasi pada preview/logik reminder puasa.
- Validation:
  - `flutter analyze` lulus,
  - `flutter test` lulus.

Latest update (17 Feb 2026 - Functionality & Test Patch):
- Tambah `PrayerCalculationService` (kiraan astronomi tempatan) dan wire ke `AppController`.
- Fallback tempatan aktif bila API waktu solat gagal.
- Preference kiraan (`method`, `asar`, `high latitude`) kini trigger kiraan semula waktu secara langsung.
- Notifications diperkukuh:
  - bunyi azan global + per-waktu,
  - `respect silent mode` diintegrasi hingga ke scheduling/preview.
- Persistence setting baharu ditambah di `TasbihStore` + export/import settings.
- Ditambah widget tests baharu untuk flow Settings kritikal:
  - zone/change zone,
  - select all/clear notifikasi,
  - azan sound picker,
  - fasting preview,
  - custom tasbih target.
- Test & analysis: lulus (`flutter analyze`, `flutter test`).

Latest update (17 Feb 2026 - Settings Next Patch):
- Settings UX dipolish dengan aliran `progressive disclosure` yang lebih minimal.
- Prayer Times detail:
  - `Zone` dipaparkan jelas untuk mod auto/manual.
  - `Change zone` bottom sheet ditambah (search + recent + loading/empty state).
- Prayer Calculation subpage ditambah:
  - calculation method picker,
  - Asar method,
  - high latitude rule,
  - manual minute adjustments per prayer.
- Notifications detail ditambah:
  - `Azan sound` picker modal,
  - `Respect silent mode` toggle,
  - quick actions `Select all` / `Clear` untuk prayer chips.
- Fasting detail ditambah `Preview upcoming dates` (5 tarikh seterusnya).
- Tasbih detail: `Custom` target kini fully functional + nilai custom semasa dipaparkan.
- State/persistence baru ditambah dalam `AppController` + `TasbihStore`.
- `NotificationService` kini support `respectSilentMode` pada jadual notifikasi dan preview bunyi.

Last update (17 Feb 2026):
- Branding: nama app kekal `JagaSolat`, tagline splash ditukar ke `Jangan dok tinggai solat.`.
- Times/Home: countdown ring kanan dibuang sepenuhnya.
- Countdown dipindah ke kiri bawah dalam hero dengan format English penuh (`5 hours 59 minutes`) dan caption `Before Subuh begins`.
- Kad kecil `Seterusnya ...` bawah hero dibuang untuk elak duplication.
- Pinned header atas dibuang terus untuk layout yang lebih bersih.
- Refresh countdown di hero ditukar kepada setiap 1 minit.
- Hero card dipolish: hierarchy baru (`NEXT PRAYER`, tajuk + masa sebaris), metadata digabung dalam 1 chip, CTA check-in state dipermudah.
- Hero action state: pre-check-in guna status pill `Check-in opens at HH:mm`, active guna `Mark done`, selesai guna pill `Marked`.
- Tasbih: UI polish (ripple + haptic + animated scale + animated progress ring + stats chips + milestone banner).
- Bahasa app diseragamkan melalui `AppController.tr()` berdasarkan pilihan BM/EN pengguna.
- Navigation label ditukar ke `Times/Qibla/Tasbih/Settings`.
- Splash screen dipolish: entrance animation staggered (logo/text/loader), matte gradient, dan loader ditukar ke `3 dots pulse` (bukan circular).
- Tempoh splash dipanjangkan ke ~`3.2s` supaya animation lebih terasa.

Previous update (16 Feb 2026):
- Home page dikemas dengan hierarchy yang lebih jelas (hero + jadual).
- `QuickAction` dalam Home dibuang untuk elak `double navigation`.
- Bahasa pada Home dan bottom nav diseragamkan ke BM.
- Pinned header dipendekkan supaya tidak terlalu padat.
- Status jadual diperkukuh (`SEMASA`, `Seterusnya`, `Selesai`) dengan visual berbeza.
- Hero action diringankan: bila selesai, guna chip `Sudah ditanda` + CTA `Tunda 5 min`.
- Metadata lokasi/freshness ditukar kepada chip.
- Ditambah `NextPrayerStrip` (ringkasan waktu seterusnya).
- Ditambah `pull-to-refresh` sebenar pada Home (`RefreshIndicator`).
- Ditambah quick insights (`Selesai`, `Baki`, `Streak`) dan collapse untuk row selesai.
- Micro-polish spacing/touch target dibuat untuk konsistensi.

Next patch (cadangan kerja seterusnya):
- [ ] Standardize remaining hardcoded non-English strings in notification + service error messages.
- [ ] Add widget tests for hero state transition (`Check-in opens` -> `Mark done` -> `Marked`).
- [ ] Add a splash timing config constant (easy tuning without touching logic).
- [ ] Add accessibility pass for hero actions (tap target + semantics labels).
- [ ] Decide final tagline language policy (keep localized tagline vs full-English branding).
