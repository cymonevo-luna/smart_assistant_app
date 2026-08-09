// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Jarvis';

  @override
  String get appTagline => 'Asisten AI Anda, siap diperintah.';

  @override
  String get home => 'Beranda';

  @override
  String get tasks => 'Tugas';

  @override
  String get calendar => 'Kalender';

  @override
  String get messages => 'Pesan';

  @override
  String get assistant => 'Asisten';

  @override
  String get assistantProcessing => 'Memproses...';

  @override
  String get assistantSpeaking => 'Berbicara...';

  @override
  String get assistantListening => 'Mendengarkan…';

  @override
  String get assistantTapToSpeak => 'Ketuk untuk berbicara';

  @override
  String get assistantWidgetSignInRequired =>
      'Masuk untuk menggunakan widget asisten';

  @override
  String get profile => 'Profil';

  @override
  String get overview => 'Ringkasan';

  @override
  String get recentActivity => 'Aktivitas Terbaru';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get themeColor => 'Warna Tema';

  @override
  String get language => 'Bahasa';

  @override
  String greeting(String name) {
    return 'Selamat pagi, $name';
  }

  @override
  String get haveAGreatDay => 'Semoga harimu menyenangkan!';

  @override
  String get welcomeBack => 'Selamat Datang Kembali';

  @override
  String get signInToContinue => 'Masuk untuk melanjutkan ke akunmu';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'contoh@email.com';

  @override
  String get password => 'Kata Sandi';

  @override
  String get passwordHint => 'Masukkan kata sandimu';

  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get login => 'Masuk';

  @override
  String get orContinueWith => 'atau lanjut dengan';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get dontHaveAccount => 'Belum punya akun? ';

  @override
  String get register => 'Daftar';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get signUpToGetStarted => 'Daftar untuk memulai';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get confirmPassword => 'Konfirmasi Kata Sandi';

  @override
  String get alreadyHaveAccount => 'Sudah punya akun? ';

  @override
  String get signIn => 'Masuk';

  @override
  String get settings => 'Pengaturan';

  @override
  String get myProfile => 'Profil Saya';

  @override
  String get achievements => 'Pencapaian';

  @override
  String get activityHistory => 'Riwayat Aktivitas';

  @override
  String get savedItems => 'Item Tersimpan';

  @override
  String get projects => 'Proyek';

  @override
  String get completed => 'Selesai';

  @override
  String get account => 'Akun';

  @override
  String get personalInformation => 'Informasi Pribadi';

  @override
  String get security => 'Keamanan';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get privacy => 'Privasi';

  @override
  String get preferences => 'Preferensi';

  @override
  String get appearance => 'Tampilan';

  @override
  String get darkMode => 'Mode Gelap';

  @override
  String get about => 'Tentang';

  @override
  String get logout => 'Keluar';

  @override
  String get english => 'Inggris';

  @override
  String get fieldRequired => 'Bidang ini wajib diisi';

  @override
  String get invalidEmail => 'Masukkan alamat email yang valid';

  @override
  String get passwordTooShort => 'Kata sandi minimal 6 karakter';

  @override
  String get passwordsDoNotMatch => 'Kata sandi tidak cocok';

  @override
  String get wakeWord => 'Kata bangun';

  @override
  String get activeListening => 'Dengarkan aktif';

  @override
  String get activeListeningSubtitle =>
      'Menjalankan pendengar hemat daya di perangkat untuk kata bangun. Dampak battery minimal.';

  @override
  String get wakeWordRequired => 'Kata bangun tidak boleh kosong';

  @override
  String get wakeWordFixedNotice =>
      'Kata bangun kustom belum didukung — dengarkan aktif hanya merespons \"Jarvis\".';

  @override
  String listeningForWakeWord(String wakeWord) {
    return 'Mendengarkan $wakeWord…';
  }

  @override
  String get assistantSettingsSaveFailed =>
      'Tidak dapat menyimpan pengaturan. Menampilkan nilai yang tersimpan.';

  @override
  String get locationReminderDistance => 'Jarak pengingat lokasi';

  @override
  String locationReminderDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String get plugins => 'Plugin';

  @override
  String get managePlugins => 'Kelola Plugin';

  @override
  String get pluginsInstalledTab => 'Terpasang';

  @override
  String get pluginsAvailableTab => 'Tersedia';

  @override
  String get pluginStore => 'Toko Plugin';

  @override
  String get myPlugins => 'Plugin Saya';

  @override
  String get install => 'Pasang';

  @override
  String get uninstall => 'Copot';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Coba lagi';

  @override
  String get enabled => 'Aktif';

  @override
  String get pluginStoreEmpty => 'Belum ada plugin tersedia.';

  @override
  String get noPluginsInstalled => 'Belum ada plugin terpasang';

  @override
  String get noPluginsInstalledSubtitle =>
      'Jelajahi toko plugin untuk memperluas asistenmu.';

  @override
  String get browsePluginStore => 'Jelajahi Toko Plugin';

  @override
  String get pluginLoadFailed =>
      'Tidak dapat memuat plugin. Silakan coba lagi.';

  @override
  String get pluginActionFailed => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String pluginInstalled(String name) {
    return '$name terpasang';
  }

  @override
  String pluginUninstalled(String name) {
    return '$name dicopot';
  }

  @override
  String get uninstallPlugin => 'Copot plugin?';

  @override
  String uninstallPluginConfirm(String name) {
    return 'Hapus $name dari asistenmu?';
  }

  @override
  String get setupNotStarted => 'Perlu setup';

  @override
  String get setupInProgress => 'Setup berjalan';

  @override
  String get setupCompleted => 'Siap';

  @override
  String get setupFailed => 'Setup gagal';

  @override
  String get pluginSetup => 'Setup Plugin';

  @override
  String get pluginOAuthSetupInstructions =>
      'Hubungkan akun Google agar plugin ini dapat mengakses kalender dan layanan terkait.';

  @override
  String get pluginSetupInstructions =>
      'Hubungkan akun Google agar plugin ini dapat mengakses kalender dan layanan terkait.';

  @override
  String get pluginFormSetupInstructions =>
      'Tempel kunci API dari dasbor Composio Anda. Aplikasi terhubung akan ditemukan secara otomatis.';

  @override
  String get pluginSetupApiKeyRequired => 'Kunci API diperlukan';

  @override
  String get pluginSetupOAuthRequired => 'Koneksi akun diperlukan';

  @override
  String get composioApiKeyLabel => 'Kunci API Composio';

  @override
  String get composioApiKeyRequired => 'Kunci API wajib diisi';

  @override
  String get composioConnectedApps => 'Aplikasi terhubung';

  @override
  String get composioNoConnectedApps =>
      'Belum ada aplikasi terhubung. Hubungkan aplikasi di dasbor Composio untuk menggunakannya di sini.';

  @override
  String get composioConnectApps => 'Hubungkan aplikasi di Composio';

  @override
  String get composioDashboardUrl => 'https://app.composio.dev';

  @override
  String get done => 'Selesai';

  @override
  String get saveApiKey => 'Simpan kunci API';

  @override
  String get connectGoogleAccount => 'Hubungkan Akun Google';

  @override
  String get pluginSetupWaiting => 'Menunggu otorisasi…';

  @override
  String get pluginSetupSuccess => 'Setup selesai! Plugin ini siap digunakan.';

  @override
  String get pluginSetupFailed => 'Setup tidak dapat diselesaikan.';

  @override
  String get pluginSetupRetry => 'Coba lagi';

  @override
  String get pluginsSetupIncompleteBanner =>
      'Beberapa plugin perlu disetup sebelum dapat digunakan.';

  @override
  String get assistantCompleteSetup => 'Selesaikan setup';

  @override
  String get assistantManagePlugins => 'Kelola plugin';

  @override
  String get openInBrowser => 'Buka di browser';

  @override
  String get reminderNotificationsTitle => 'Notifikasi pengingat';

  @override
  String get reminderNotificationsDescription =>
      'Notifikasi pengingat aktif saat plugin Reminder terpasang. Aplikasi menyinkronkan pengingat dari akunmu dan menampilkan peringatan lokal pada waktu yang dijadwalkan.';

  @override
  String get reminderNotificationsRequestPermission =>
      'Periksa izin notifikasi';

  @override
  String get reminderNotificationsPermissionRequested =>
      'Izin notifikasi diperiksa. Pengingat akan disinkronkan jika diizinkan.';
}
