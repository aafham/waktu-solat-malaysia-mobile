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

## Changelog Ringkas
Update terkini:
- Android launcher icon kini adaptive + legacy menggunakan style premium minimalist (navy matte + simbol mihrab kuning).
- Android widget kini 3 saiz dengan fungsi berbeza:
  - `2x1` Next Prayer Compact
  - `2x2` Next Prayer + Context
  - `3x2` Today Progress
- Widget picker previews (`2x1/2x2/3x2`) sudah di-brand semula, bukan logo Flutter default.
- Widget follow bahasa sistem telefon (BM/EN), termasuk label dan copy utama.
- Countdown widget dipaparkan dalam perkataan penuh (`jam/minit` atau `hour/minute`), bukan format ringkas.
- Tajuk page utama (`Waktu Solat`, `Qiblat`, `Digital Tasbih`, `Tetapan`) kini guna style typography yang konsisten merentas semua screen.
- Top metadata Qibla (`lokasi + GPS + status`) dipisahkan dari tajuk untuk hierarchy lebih clean dan selari dengan page lain.
- Splash app dikemas:
  - dismiss berasaskan readiness (`isLoading`) dengan minimum display + fallback timeout (bukan delay statik 3.2s),
  - Android native launch theme (`values` + `values-v31`) diselaraskan ke dark matte supaya tiada white flash sebelum Flutter render.
- Loading state page `Waktu Solat` dirombak kepada skeleton berstruktur (title/date + hero + schedule rows) untuk hierarchy lebih jelas.
- Home kini tambah kad Ramadan: paparan `Waktu Sahur` (Imsak) dan `Waktu Berbuka` (Maghrib) bila mode Ramadan aktif.
- Mode Ramadan kini hybrid:
  - auto aktif bila tarikh Hijri semasa berada dalam Ramadan,
  - masih boleh diaktifkan manual dari Settings di luar Ramadan.
- Rollover tarikh:
  - Tarikh Hijri aktif berubah pada waktu `Maghrib` (bukan jam 12 malam),
  - Tarikh Masihi kekal ikut sistem biasa (bertukar pada jam 12:00 malam).
- Default `Offset Hijri` kini `+1` untuk pengguna baharu (install fresh).
  - Jika pengguna sudah pernah set offset sendiri, nilai simpanan lama kekal digunakan.
- Deep link tap widget kekal ke `myapp://times`.

Status validation:
- `flutter analyze` lulus.
- `flutter test` lulus.
- `:app:compileDebugKotlin` lulus.
- `:app:mergeDebugResources` lulus.

Cadangan next tasks:
- Tambah screenshot rasmi widget 3 saiz dalam README untuk rujukan QA/design.
- Tambah widget integration test asas (binding key + layout type per provider).
- Audit baki hardcoded strings di service error messages untuk konsistensi BM/EN.
