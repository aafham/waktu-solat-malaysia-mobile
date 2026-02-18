import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.languageCode);

  final String languageCode;

  static const supportedLocales = <Locale>[
    Locale('ms'),
    Locale('en'),
  ];

  static const _strings = <String, Map<String, String>>{
    'page_title_times': {'ms': 'Waktu Solat', 'en': 'Prayer Times'},
    'page_title_qibla': {'ms': 'Qiblat', 'en': 'Qibla'},
    'page_title_tasbih': {'ms': 'Digital Tasbih', 'en': 'Digital Tasbih'},
    'page_title_settings': {'ms': 'Tetapan', 'en': 'Settings'},
    'page_subtitle_settings': {
      'ms': 'Sesuaikan aplikasi anda',
      'en': 'Personalize your app'
    },
    'nav_times': {'ms': 'Waktu', 'en': 'Times'},
    'nav_qibla': {'ms': 'Qiblat', 'en': 'Qibla'},
    'nav_tasbih': {'ms': 'Tasbih', 'en': 'Tasbih'},
    'nav_settings': {'ms': 'Tetapan', 'en': 'Settings'},
    'times_before_next': {
      'ms': 'Sebelum waktu berikutnya bermula',
      'en': 'Before next prayer begins'
    },
    'times_checkin_success': {
      'ms': 'Check-in berjaya.',
      'en': 'Check-in successful.'
    },
    'times_tap_to_mark': {
      'ms': 'Tekan untuk tandakan, tekan lama untuk undo.',
      'en': 'Tap to mark done, long press to undo.'
    },
    'times_pull_refresh': {
      'ms': 'Tarik ke bawah untuk cuba semula.',
      'en': 'Pull down to try again.'
    },
    'times_snooze_5': {'ms': 'Tunda 5 min', 'en': 'Snooze 5 min'},
    'times_checkin_open_at': {
      'ms': 'Check-in dibuka pada {time}',
      'en': 'Check-in opens at {time}'
    },
    'tasbih_tap_add': {'ms': 'Tekan untuk tambah', 'en': 'Tap to add'},
    'qibla_details': {'ms': 'Butiran', 'en': 'Details'},
    'history_title': {'ms': 'Sejarah Solat', 'en': 'Prayer History'},
    'history_subtitle': {
      'ms': 'Ringkasan 7 hari terakhir',
      'en': 'Last 7 days summary'
    },
    'history_empty': {'ms': 'Belum ada rekod.', 'en': 'No records yet.'},
    'history_day_done': {
      'ms': '{done}/{target} selesai',
      'en': '{done}/{target} done'
    },
    'about_privacy': {'ms': 'Privasi', 'en': 'Privacy'},
    'about_feedback': {'ms': 'Maklum balas', 'en': 'Feedback'},
    'about_version': {'ms': 'Versi', 'en': 'Version'},
    'about_build': {'ms': 'Build', 'en': 'Build'},
    'prayer_calc_reset_all': {
      'ms': 'Reset semua pelarasan',
      'en': 'Reset all adjustments'
    },
    'prayer_calc_reset_confirm_title': {
      'ms': 'Reset semua pelarasan minit?',
      'en': 'Reset all minute adjustments?'
    },
    'prayer_calc_reset_confirm_body': {
      'ms': 'Semua nilai akan kembali ke 0 minit.',
      'en': 'All values will return to 0 minutes.'
    },
    'permission_location_title': {
      'ms': 'Akses lokasi ditolak',
      'en': 'Location access denied'
    },
    'permission_location_body': {
      'ms': 'Pilih zon manual untuk teruskan paparan waktu solat.',
      'en': 'Choose a manual zone to continue prayer times.'
    },
    'permission_manual_zone_cta': {
      'ms': 'Pilih zon manual',
      'en': 'Choose manual zone'
    },
    'hijri_offset': {'ms': 'Offset Hijri', 'en': 'Hijri offset'},
    'hijri_offset_helper': {
      'ms': 'Laraskan tarikh Hijri untuk paparan dan peringatan puasa.',
      'en': 'Adjust Hijri date for display and fasting reminders.'
    },
    'hijri_unavailable': {
      'ms': 'Hijri tidak tersedia',
      'en': 'Hijri unavailable'
    },
    'hijri_today_preview': {
      'ms': 'Hijri hari ini: {date} (offset {offset})',
      'en': 'Today Hijri: {date} (offset {offset})'
    },
    'error_location_unavailable': {
      'ms': 'Lokasi tidak tersedia. Sila aktifkan GPS atau pilih zon manual.',
      'en':
          'Location is unavailable. Please enable GPS or choose a manual zone.'
    },
    'error_slow_connection': {
      'ms': 'Sambungan perlahan. Tarik ke bawah untuk cuba semula.',
      'en': 'Connection is slow. Pull down to try again.'
    },
    'error_server_unavailable': {
      'ms':
          'Data belum tersedia dari pelayan. Data simpanan akan digunakan jika ada.',
      'en':
          'Data is not yet available from server. Cached data will be used when available.'
    },
    'error_generic': {
      'ms': 'Data tidak dapat dimuatkan sekarang. Cuba sebentar lagi.',
      'en': 'Unable to load data right now. Please try again shortly.'
    },
    'error_action_open_location': {
      'ms': 'Buka tetapan lokasi',
      'en': 'Open location settings'
    },
    'error_action_open_app': {
      'ms': 'Buka tetapan aplikasi',
      'en': 'Open app settings'
    },
    'error_action_manual_zone': {
      'ms': 'Guna zon manual',
      'en': 'Use manual zone'
    },
  };

  String text(String key, {Map<String, String> params = const {}}) {
    final value = _strings[key]?[languageCode] ?? _strings[key]?['en'] ?? key;
    if (params.isEmpty) {
      return value;
    }
    var resolved = value;
    for (final entry in params.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', entry.value);
    }
    return resolved;
  }
}
