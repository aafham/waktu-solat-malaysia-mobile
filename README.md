# Waktu Solat Malaysia Mobile (Flutter)

Aplikasi Android (APK) untuk pengguna Malaysia dengan ciri:
- Waktu solat ikut zon Malaysia
- Auto detect lokasi pengguna (GPS)
- Kompas kiblat
- Tasbih digital
- Notifikasi masuk waktu (bunyi default + vibrate)
- Splash screen semasa app dibuka

## Status projek
Project Flutter ini sudah lengkap dengan struktur utama termasuk folder platform Android.

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
- `lib/services/prayer_service.dart` - API waktu solat + pemilihan zon
- `lib/services/location_service.dart` - GPS/permission lokasi
- `lib/services/notification_service.dart` - jadual notifikasi waktu solat
- `lib/services/qibla_service.dart` - kiraan arah kiblat
- `lib/services/tasbih_store.dart` - simpanan tasbih + settings
- `lib/features/home/home_page.dart` - paparan waktu solat
- `lib/qibla_page.dart` - kompas kiblat
- `lib/features/tasbih/tasbih_page.dart` - tasbih digital
- `lib/features/settings/settings_page.dart` - tetapan app

## Sumber API
- `https://api.solat.my/v2/locations`
- `https://api.solat.my/v2/times/{ZONE_CODE}`

## Nota teknikal
- Timezone notifikasi diset ke `Asia/Kuala_Lumpur`.
- Notifikasi sekarang guna bunyi default Android.
- Untuk azan custom, letak fail audio di `android/app/src/main/res/raw/` dan setkan custom notification sound channel.

## Troubleshooting ringkas
- `flutter`/`dart` tak dijumpai: semak PATH dan restart terminal.
- Notifikasi tak keluar: semak permission notification (Android 13+) dan battery optimization.
- Kompas tak stabil: kalibrasi sensor kompas peranti.
- Lokasi gagal: hidupkan GPS dan beri permission lokasi.
