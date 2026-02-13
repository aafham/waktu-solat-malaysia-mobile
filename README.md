# Waktu Solat Malaysia Mobile (Flutter)

Aplikasi Android untuk pengguna Malaysia dengan fokus pada:
- Waktu solat ikut zon Malaysia (daily + monthly)
- Auto detect lokasi (GPS) + manual zone fallback
- Kompas kiblat
- Tasbih digital (focus mode, haptic, zikir presets)
- Notifikasi masuk waktu (per-waktu toggle, snooze 5/10 minit, profile bunyi)
- Cache offline + retry API
- UI accessibility (text scale + high contrast)
- Widget homescreen Android (tasbih quick view)

## Status Projek
Struktur utama aplikasi sudah lengkap dan sedang aktif ditambah baik dari segi UI/UX serta reliability.

## What’s New (Latest)
- Migrasi API ke `solat.my/api` dengan fallback endpoint legacy.
- Parser API disokong untuk format response baru dan lama.
- Home Hero Card + state color by prayer.
- Data freshness banner (`Data live` / `Data cache`) + error action CTA.
- Tab Bulanan dengan filter (`Semua/Subuh/Maghrib`) + heatmap ringkas.
- Settings disusun ikut section (Notifikasi, Lokasi, Paparan, Data & Backup).
- Share ringkasan “hari ini”.
- Backup/restore settings melalui JSON.
- Health logs lokal untuk debug ringkas.
- CI asas melalui GitHub Actions.

## Prasyarat
- Flutter SDK
- Android Studio + Android SDK
- Peranti fizikal Android atau emulator

Semak setup:
```bash
flutter doctor
```

Jika command `flutter` tidak dikenali (Windows), tambah Flutter ke PATH.
Contoh: `C:\src\flutter\bin`

## Quick Start
Jalankan dari root project:
```bash
flutter pub get
flutter run
```

## Test & Analyze
```bash
flutter test
flutter analyze
```

## Build APK
```bash
flutter build apk --release
```

Lokasi output:
- `build/app/outputs/flutter-apk/app-release.apk`

## Konfigurasi Android (Manifest)
Fail: `android/app/src/main/AndroidManifest.xml`

Permission minimum:
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Receiver notifikasi:
```xml
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    android:exported="false" />

<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
    </intent-filter>
</receiver>
```

Receiver widget homescreen:
```xml
<receiver
    android:name=".TasbihWidgetProvider"
    android:exported="false">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/tasbih_widget_info" />
</receiver>
```

## Struktur Kod Ringkas
- `lib/main.dart` - entry app + splash + bottom navigation
- `lib/state/app_controller.dart` - state utama + orchestrator flow
- `lib/services/prayer_service.dart` - fetch API + retry + cache + parser
- `lib/services/location_service.dart` - GPS + permission
- `lib/services/notification_service.dart` - schedule notifikasi + snooze
- `lib/services/qibla_service.dart` - kiraan arah kiblat
- `lib/services/tasbih_store.dart` - storage settings/tasbih
- `lib/features/home/home_page.dart` - home dashboard + quick actions
- `lib/features/monthly/monthly_page.dart` - jadual bulanan + heatmap/filter
- `lib/features/qibla/qibla_page.dart` - paparan kompas kiblat
- `lib/features/tasbih/tasbih_page.dart` - tasbih + focus mode + presets
- `lib/features/settings/settings_page.dart` - tetapan berseksyen + backup/restore
- `test/prayer_service_test.dart` - unit test parser API

## API Digunakan
- `https://solat.my/api/locations`
- `https://solat.my/api/daily/{ZONE_CODE}`
- `https://solat.my/api/monthly/{ZONE_CODE}`

## Nota Teknikal
- Timezone notifikasi: `Asia/Kuala_Lumpur`
- Data zon/waktu disimpan dalam `SharedPreferences` untuk fallback offline
- Refresh countdown setiap minit + auto refresh penuh bila hari bertukar
- Audio default notifikasi Android digunakan melainkan profile diubah
- CI workflow: `.github/workflows/flutter-ci.yml`

## Troubleshooting Ringkas
- `flutter`/`dart` tak dijumpai: semak PATH dan restart terminal
- Notifikasi tak keluar: semak permission notification + battery optimization
- Exact alarm diblok: benarkan `Alarms & reminders` untuk app
- Kompas tak stabil: kalibrasi sensor kompas (gerakan angka 8)
- Lokasi gagal: aktifkan GPS atau tukar ke zon manual
- Data tak update: pull-to-refresh atau `Refresh data sekarang` di Settings

## Limitasi Semasa
- Export bulanan masih CSV (belum PDF/PNG native)
- Widget homescreen kini fokus pada tasbih (belum next prayer countdown penuh)
- Telemetry masih lokal (belum hantar ke backend observability)
