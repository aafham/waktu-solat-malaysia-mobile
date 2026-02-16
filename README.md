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
- `Settings` dirombak ke gaya card sections.
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
- UI kini `English-first` secara global.
- Nama waktu solat kekal istilah standard Malaysia (`Imsak`, `Subuh`, `Zohor`, `Asar`, `Maghrib`, `Isyak`).
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

## Log Patch Terkini (Rujukan Next)
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
- Bahasa app ditukar ke English sepenuhnya melalui `AppController.tr()`; string fallback BM hardcoded dibersihkan.
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
