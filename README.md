# JagaSolat (Flutter)

Aplikasi mudah alih untuk bantu pengguna Malaysia jaga amalan harian dengan 3 fokus utama:
- Waktu Solat
- Qiblat
- Zikir

## Status UI Terkini
Kemaskini terkini membawa gaya visual gelap yang konsisten di semua page:
- Palette navy gelap + kad biru-kelabu rounded.
- Splash screen Android + Flutter yang konsisten.
- `Settings` dirombak ke gaya card sections.
- Page `Zikir` dikemas dari segi hierarchy, kontras, progress ring, dan milestone.
- Page `Qiblat` dikemas dengan struktur status + kompas + panduan kalibrasi yang lebih jelas.

## Fokus Utama Aplikasi
- `Waktu Solat`: waktu harian ikut zon Malaysia, countdown ke waktu seterusnya, check-in solat harian.
- `Qiblat`: kompas qiblat dengan bacaan darjah, indikator ketepatan, status aktif/henti, dan panduan kalibrasi.
- `Zikir`: tasbih digital dengan sasaran pusingan (33/99/100), batch tambah, auto reset harian, statistik harian/mingguan/streak.

## Navigasi Semasa
Bottom navigation:
- `Waktu`
- `Qiblat`
- `Zikir`
- `Tetapan`

## Ciri Tambahan
- Sokongan bahasa `BM/EN` (boleh tukar di `Settings`).
- Lokasi automatik (GPS) + zon manual.
- Notifikasi waktu solat (tetapan per waktu + lead time awal notifikasi).
- Travel mode auto tukar zon.
- Reminder puasa (`Ramadhan`, `Isnin/Khamis`, `Ayyamul Bidh`).
- Mod kontras tinggi dan saiz teks boleh laras.
- Onboarding setup awal (notifikasi + lokasi automatik).
- Simpanan setempat (`SharedPreferences`) untuk fallback data.
- Android home widget (paparan waktu seterusnya + countdown + tasbih).
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

## Struktur Kod Ringkas
- `lib/main.dart` - inisialisasi app, tema global, splash, navigasi bawah.
- `lib/state/app_controller.dart` - state utama dan aliran data.
- `lib/features/home/home_page.dart` - skrin Waktu Solat (hero, countdown, check-in, freshness pill).
- `lib/features/qibla/qibla_page.dart` - skrin Qiblat + indikator ketepatan.
- `lib/features/tasbih/tasbih_page.dart` - skrin Zikir + progress ring/milestone.
- `lib/features/settings/settings_page.dart` - tetapan gaya kad + toggle BM/EN.
- `lib/features/onboarding/onboarding_page.dart` - onboarding + setup awal.
- `lib/features/monthly/monthly_page.dart` - jadual bulanan + eksport.
- `lib/services/prayer_service.dart` - API waktu solat, parser, cache.
- `lib/services/location_service.dart` - GPS dan permission.
- `lib/services/notification_service.dart` - jadual notifikasi + lead time.
- `lib/services/qibla_service.dart` - kiraan arah kiblat.
- `lib/services/tasbih_store.dart` - simpanan kiraan/tetapan/language.

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

## Troubleshooting Ringkas
- `flutter`/`dart` tidak dijumpai: semak PATH dan restart terminal.
- Notifikasi tidak keluar: semak permission notifikasi dan battery optimization.
- Kompas tidak stabil: buat kalibrasi sensor (gerakan angka 8).
- Lokasi gagal: aktifkan GPS atau guna zon manual.
- Data lambat/tiada: tarik ke bawah untuk muat semula.
