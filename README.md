# Waktu Solat Malaysia Mobile (Flutter)

Aplikasi Android (APK) untuk pengguna Malaysia dengan ciri:
- Waktu solat ikut zon Malaysia
- Jadual bulanan waktu solat
- Auto detect lokasi pengguna (GPS)
- Kompas kiblat
- Tasbih digital
- Notifikasi masuk waktu (bunyi default + vibrate + per-waktu toggle)
- Snooze peringatan 5/10 minit
- Cache offline + retry API bila rangkaian tidak stabil
- Tetapan saiz teks + high contrast mode (aksesibiliti)
- Splash screen semasa app dibuka
- Zon kegemaran + zon terkini (recent)
- Auto refresh bila masuk hari baru

## Status projek
Project Flutter ini sudah lengkap dengan struktur utama termasuk folder platform Android.

## What’s New (kemas kini terbaru)
- Migrasi endpoint ke `solat.my/api` + fallback endpoint legacy.
- Parser API disokong untuk format response baru dan lama.
- Paparan status data di Home (API success/fail/cache hit).
- Tab Bulanan ditambah untuk semak waktu solat sebulan.
- Tetapan notifikasi ikut waktu solat (Imsak/Subuh/.../Isyak).
- Test parser asas ditambah di `test/prayer_service_test.dart`.

## Prasyarat
Pastikan mesin anda ada:
- Flutter SDK
- Android Studio + Android SDK
- Peranti fizikal Android atau emulator

Semak dengan:

```bash
flutter doctor
```

Jika command `flutter` tak dikenali, tambah Flutter ke PATH (Windows):
- Contoh path: `C:\src\flutter\bin`
- Tutup dan buka semula terminal selepas update PATH

## Quick Start (dari repo ini)
Jalankan command berikut di root project:

```bash
flutter pub get
flutter run
```

## Jalankan test
```bash
flutter test
```

## Analisis kod
```bash
flutter analyze
```

## Konfigurasi Android (wajib)
Fail: `android/app/src/main/AndroidManifest.xml`

### 1) Tambah permission dalam tag `<manifest>`

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### 2) Tambah receiver dalam tag `<application>`

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

## Build APK release

```bash
flutter build apk --release
```

Lokasi APK:
- `build/app/outputs/flutter-apk/app-release.apk`

## Struktur kod ringkas
- `lib/main.dart` - entry app + splash screen + bottom navigation
- `lib/state/app_controller.dart` - state utama app
- `lib/services/prayer_service.dart` - API waktu solat + retry + cache + parser
- `lib/services/location_service.dart` - GPS/permission lokasi
- `lib/services/notification_service.dart` - jadual notifikasi + snooze reminder
- `lib/services/qibla_service.dart` - kiraan arah kiblat
- `lib/services/tasbih_store.dart` - simpanan tasbih + settings
- `lib/features/home/home_page.dart` - paparan waktu solat
- `lib/features/monthly/monthly_page.dart` - paparan jadual bulanan
- `lib/features/qibla/qibla_page.dart` - kompas kiblat
- `lib/features/tasbih/tasbih_page.dart` - tasbih digital
- `lib/features/settings/settings_page.dart` - tetapan app

## Sumber API
- `https://solat.my/api/locations`
- `https://solat.my/api/daily/{ZONE_CODE}`
- `https://solat.my/api/monthly/{ZONE_CODE}`

## Nota teknikal
- Timezone notifikasi diset ke `Asia/Kuala_Lumpur`.
- Notifikasi sekarang guna bunyi default Android.
- Data zon/waktu disimpan ke local cache (`SharedPreferences`) untuk fallback offline.
- Refresh data berlaku setiap minit untuk countdown, dan auto refresh penuh bila hari bertukar.
- Untuk azan custom, letak fail audio di `android/app/src/main/res/raw/` dan setkan custom notification sound channel.

## Troubleshooting ringkas
- `flutter`/`dart` tak dijumpai: semak PATH dan restart terminal.
- Notifikasi tak keluar: semak permission notification (Android 13+) dan battery optimization.
- Kompas tak stabil: kalibrasi sensor kompas peranti.
- Lokasi gagal: hidupkan GPS dan beri permission lokasi.
- Data tak update: tarik skrin ke bawah (pull-to-refresh) atau tekan `Refresh data sekarang` di Settings.

## Limitasi semasa
- Homescreen widget Android belum diimplement.
- Export jadual bulanan ke PDF/PNG belum diimplement.
- Telemetry masih local counter sahaja (belum hantar ke backend).
