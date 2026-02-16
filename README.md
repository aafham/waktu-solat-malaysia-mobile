# Waktu Solat Malaysia Mobile (Flutter)

Aplikasi mudah alih untuk pengguna Malaysia yang memaparkan waktu solat, kompas kiblat, tasbih digital, serta notifikasi masuk waktu dengan reka bentuk moden dan konsisten.

## Ciri Utama
- Waktu solat harian mengikut zon Malaysia.
- Jadual bulanan dengan penapis `Semua / Subuh / Maghrib`.
- Pengesanan lokasi automatik (GPS) + pilihan zon manual.
- `Travel mode` untuk tukar zon automatik bila lokasi berubah.
- Kompas kiblat dengan paparan arah, status aktif, dan bacaan darjah.
- Panduan kalibrasi kompas dalam aplikasi.
- Tasbih digital dengan preset zikir, mod fokus, haptic, dan kiraan batch.
- Analitik tasbih: kiraan hari ini, 7 hari, streak, dan rekod terbaik.
- Notifikasi waktu solat dengan tetapan per-waktu, profil bunyi, tunda 5/10 minit, dan action lock-screen.
- Pratonton bunyi notifikasi per waktu terus dari tetapan.
- Peringatan puasa sunat (Isnin/Khamis dan Ayyamul Bidh).
- Cache setempat untuk sokongan rangkaian tidak stabil.
- Tetapan aksesibiliti: skala teks dan mod kontras tinggi.
- Sandaran/pulih tetapan melalui JSON.
- Eksport jadual ke format iCal (`.ics`) untuk integrasi kalendar.
- Onboarding ringkas untuk pengguna kali pertama.
- Widget Android paparan `next prayer + countdown + tasbih`.

## Kemaskini Terkini
- Tema aplikasi diseragamkan (warna, kad, butang, input, navigation bar, snackbar).
- Semua teks UI dikonsistenkan ke Bahasa Melayu.
- Onboarding baharu (3 skrin) untuk flow awal pengguna.
- Skrin `Waktu` diperkemas dengan hierarchy seksyen lebih jelas dan kad info yang kemas.
- Skrin `Waktu` ditambah action kongsi iCal harian.
- Skrin `Bulanan` ditambah ringkasan bulan (Subuh terawal, Maghrib terlewat, jumlah hari).
- Skrin `Bulanan` ditambah action kongsi iCal bulanan.
- Skrin `Kiblat` ditambah bacaan `Arah semasa` dan `Ralat` dalam darjah.
- Skrin `Kiblat` ditambah wizard kalibrasi sensor.
- Skrin `Tasbih` ditambah progress khusus preset selain progress pusingan 33.
- Skrin `Tasbih` ditambah statistik harian/mingguan/streak.
- Skrin `Tetapan` diperkemas dengan tajuk berikon dan struktur lebih teratur.
- Tetapan notifikasi kini sokong pratonton bunyi, reminder puasa, dan travel mode.

## Prasyarat
- Flutter SDK
- Android Studio + Android SDK
- Peranti Android fizikal atau emulator

Semak setup:
```bash
flutter doctor
```

Jika command `flutter` tidak dikenali (Windows), tambah Flutter ke PATH.
Contoh: `C:\src\flutter\bin`

## Quick Start
Jalankan dari root projek:
```bash
flutter pub get
flutter run
```

## Ujian & Analisis
```bash
flutter test
flutter analyze
```

## Build APK
```bash
flutter build apk --release
```

Output:
- `build/app/outputs/flutter-apk/app-release.apk`

## Konfigurasi Android (Manifest)
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
- `lib/main.dart` - inisialisasi app, tema global, navigasi bawah
- `lib/state/app_controller.dart` - state utama dan aliran data
- `lib/services/prayer_service.dart` - API waktu solat, parser, retry, cache
- `lib/services/location_service.dart` - GPS dan permission
- `lib/services/notification_service.dart` - jadual notifikasi, tunda
- `lib/features/onboarding/onboarding_page.dart` - onboarding pengguna kali pertama
- `lib/services/qibla_service.dart` - kiraan arah kiblat
- `lib/services/tasbih_store.dart` - simpanan kiraan/tetapan
- `lib/features/home/home_page.dart` - dashboard waktu + countdown + quick actions
- `lib/features/monthly/monthly_page.dart` - jadual bulanan + peta haba + ringkasan
- `lib/features/qibla/qibla_page.dart` - paparan kompas kiblat
- `lib/features/tasbih/tasbih_page.dart` - tasbih digital + mod fokus + preset
- `lib/features/settings/settings_page.dart` - tetapan notifikasi/lokasi/paparan/data
- `test/prayer_service_test.dart` - ujian unit parser API

## API Digunakan
- `https://solat.my/api/locations`
- `https://solat.my/api/daily/{ZONE_CODE}`
- `https://solat.my/api/monthly/{ZONE_CODE}`

## Nota Teknikal
- Locale default aplikasi: `ms_MY`.
- Timezone notifikasi: `Asia/Kuala_Lumpur`.
- Data zon/waktu disimpan dalam `SharedPreferences` untuk fallback.
- Refresh auto ketika hari bertukar.
- Cache bulanan dipanaskan untuk bulan semasa + bulan seterusnya.

## Troubleshooting Ringkas
- `flutter`/`dart` tidak dijumpai: semak PATH dan restart terminal.
- Notifikasi tidak keluar: semak permission notifikasi dan battery optimization.
- Penggera tepat disekat: benarkan `Alarms & reminders` untuk aplikasi.
- Kompas tidak stabil: kalibrasi sensor (gerakan angka 8).
- Lokasi gagal: aktifkan GPS atau guna zon manual.
- Data lambat/tiada: tarik ke bawah untuk muat semula.

## Limitasi Semasa
- iCal dikongsi sebagai teks `.ics` (belum export fail fizikal `.ics`).
- Widget homescreen refresh ikut kitaran widget Android (bukan real-time per saat).
- Telemetri masih setempat (belum integrasi backend observability).
