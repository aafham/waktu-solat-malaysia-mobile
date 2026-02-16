# JagaSolat (Flutter)

Aplikasi mudah alih untuk bantu pengguna Malaysia jaga amalan harian dengan 3 fokus utama:
- Waktu Solat
- Qiblat
- Zikir

## Fokus Utama Aplikasi
- `Waktu Solat`: waktu harian ikut zon Malaysia, countdown ke waktu seterusnya, check-in solat harian.
- `Qiblat`: kompas kiblat dengan bacaan darjah, status aktif, dan panduan kalibrasi.
- `Zikir`: tasbih digital dengan preset, mod fokus, haptic, statistik harian/mingguan/streak.

## Navigasi Semasa
Bottom navigation:
- `Waktu`
- `Qiblat`
- `Zikir`
- `Tetapan`

## Ciri Tambahan Yang Sudah Ada
- Lokasi automatik (GPS) + zon manual.
- Notifikasi waktu solat (termasuk tetapan per waktu).
- Travel mode auto tukar zon.
- Mod kontras tinggi dan saiz teks boleh laras.
- Simpanan setempat (`SharedPreferences`) untuk fallback data.
- Android home widget (paparan waktu seterusnya + countdown + tasbih).

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
flutter analyze
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

## Struktur Kod Ringkas
- `lib/main.dart` - inisialisasi app, tema global, navigasi bawah
- `lib/state/app_controller.dart` - state utama dan aliran data
- `lib/features/home/home_page.dart` - skrin Waktu Solat (hero, countdown, check-in)
- `lib/features/qibla/qibla_page.dart` - skrin Qiblat
- `lib/features/tasbih/tasbih_page.dart` - skrin Zikir
- `lib/features/settings/settings_page.dart` - tetapan mesra pengguna
- `lib/services/prayer_service.dart` - API waktu solat, parser, cache
- `lib/services/location_service.dart` - GPS dan permission
- `lib/services/notification_service.dart` - jadual notifikasi
- `lib/services/qibla_service.dart` - kiraan arah kiblat
- `lib/services/tasbih_store.dart` - simpanan kiraan/tetapan

## API Digunakan
- `https://solat.my/api/locations`
- `https://solat.my/api/daily/{ZONE_CODE}`
- `https://solat.my/api/monthly/{ZONE_CODE}`

## Nota Teknikal
- Locale default: `ms_MY`
- Timezone notifikasi: `Asia/Kuala_Lumpur`
- Refresh automatik bila hari bertukar
- Data zon/waktu disimpan setempat untuk kegunaan offline sementara

## Troubleshooting Ringkas
- `flutter`/`dart` tidak dijumpai: semak PATH dan restart terminal.
- Notifikasi tidak keluar: semak permission notifikasi dan battery optimization.
- Kompas tidak stabil: buat kalibrasi sensor (gerakan angka 8).
- Lokasi gagal: aktifkan GPS atau guna zon manual.
- Data lambat/tiada: tarik ke bawah untuk muat semula.
