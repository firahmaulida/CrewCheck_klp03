# CrewCheck

CrewCheck adalah aplikasi Flutter yang menggunakan Firebase untuk autentikasi pengguna, penyimpanan data tugas, dan fitur percakapan tim. README ini menjelaskan struktur utama kode dan file/folder penting di proyek, kecuali `web/manifest.json` yang merupakan template Flutter standar.

## Ringkasan Proyek

Aplikasi ini terdiri dari beberapa halaman utama:
- `LoginPage` untuk masuk
- `RegisterPage` untuk pendaftaran pengguna baru
- `DashboardPage` untuk melihat ringkasan tugas dan kemajuan proyek
- `SchedulePage` untuk melihat jadwal tugas per tanggal
- `MessagesPage` untuk daftar percakapan tim
- `ChatPage` untuk chat real-time di dalam tim
- `ProfilePage` untuk melihat dan mengedit profil pengguna

Proyek menggunakan Firebase untuk:
- `firebase_core` untuk inisialisasi Firebase
- `firebase_auth` untuk login dan pendaftaran
- `cloud_firestore` untuk menyimpan data pengguna, tugas, tim, dan pesan

## Struktur Folder Utama

- `android/`, `ios/`, `windows/`: folder platform yang dihasilkan Flutter untuk build platform spesifik.
- `lib/`: semua kode Dart aplikasi berada di sini.
- `lib/pages/`: halaman aplikasi dengan UI dan logika utama.
- `lib/widgets/`: widget bersama yang digunakan di beberapa halaman.
- `web/`: aset dan konfigurasi untuk build web.
- `pubspec.yaml`: daftar dependensi dan metadata package.

## File Utama di `lib/`

### `lib/main.dart`
- Inisialisasi Firebase dengan `Firebase.initializeApp(...)` dan konfigurasi `FirebaseOptions`.
- Menjalankan aplikasi dengan `CrewCheckApp`.
- Menentukan route aplikasi:
  - `/` → `LoginPage`
  - `/register` → `RegisterPage`
  - `/dashboard` → `DashboardPage`
  - `/schedule` → `SchedulePage`
  - `/chat` → `MessagesPage`
  - `/chat/room` → `ChatPage` dengan parameter tim
  - `/profile` → `ProfilePage`

### `lib/app_theme.dart`
- Menyediakan warna tema global seperti `colorMerah`, `colorBiru`, `colorBg`, dan lain-lain.
- Menyediakan fungsi `crewCheckTitleStyle` dan `bodyTextStyle` untuk gaya teks dengan Google Fonts.

### `lib/widgets/common_widgets.dart`
- `buildTextField(...)`: widget TextField kustom untuk formulir login/registrasi.
- `buildButton(...)`: tombol kustom besar penuh lebar.
- `buildSocialButton(...)`: tombol sosial untuk login Google/Facebook.
- `buildBottomNavBar(...)`: navigation bar bawah untuk berpindah halaman.

## Halaman (`lib/pages/`)

### `login_page.dart`
- Login menggunakan email dan password Firebase Auth.
- Menampilkan field email, password, tombol "Masuk", dan tombol sosial (Google/Facebook) untuk tampilan.
- Navigasi ke halaman register dan dashboard.

### `register_page.dart`
- Pendaftaran pengguna baru menggunakan Firebase Auth.
- Menyimpan data pengguna ke koleksi `users` Firestore:
  - `username`, `phone`, `email`
- Setelah berhasil mendaftar, pengguna diarahkan ke `DashboardPage`.

### `dashboard_page.dart`
- Menampilkan ringkasan tugas dari koleksi `tasks` Firestore.
- Mengambil jumlah proyek:
  - untuk hari ini
  - untuk minggu ini
  - yang sudah selesai
- Menampilkan daftar tugas terbaru dengan progress bar.
- Fitur `FloatingActionButton` belum diisi, hanya tampilan.

### `schedule_page.dart`
- Menampilkan pilihan tanggal 7 hari ke depan.
- Menarik tugas dari `tasks` Firestore berdasarkan tanggal yang dipilih.
- Menampilkan daftar tugas dan status checkbox.
- Checkbox belum terhubung ke update data.

### `messages_page.dart`
- Menampilkan daftar percakapan tim dari koleksi `teams` Firestore.
- Untuk setiap tim, mengambil pesan terakhir dan menampilkan ringkasannya.
- Mengarahkan ke `ChatPage` saat percakapan dipilih.

### `chat_page.dart`
- Chat real-time untuk satu tim.
- Menyimpan pesan ke `teams/{teamId}/messages` Firestore.
- Menampilkan pesan dari tim yang dipilih.
- Pesan ditandai apakah milik pengguna saat ini atau bukan.

### `profile_page.dart`
- Menampilkan informasi pengguna saat ini dari Firebase Auth.
- Menyediakan dialog untuk:
  - edit profil (nama dan telepon)
  - ganti password
  - logout
- Menyimpan perubahan profil ke koleksi `users` Firestore.
- Menampilkan tombol navigasi dan pengaturan notifikasi lokal.

## Konfigurasi Dependensi

### `pubspec.yaml`
- Dependensi utama:
  - `flutter`
  - `google_fonts`
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `cupertino_icons`
- `flutter_lints` digunakan untuk linting.

## Catatan Penting

- `web/manifest.json` tidak dijelaskan di README ini karena merupakan file template Flutter standar.
- Aplikasi saat ini terlihat terhubung ke Firebase dengan konfigurasi yang sudah ada di `main.dart`.
- Beberapa tombol `FloatingActionButton` dan fitur `onPressed` masih kosong, sehingga aplikasi kemungkinan masih dalam tahap pengembangan awal.

## Ringkasan

README ini menjelaskan semua kode utama dalam proyek `CrewCheck`, mulai dari struktur folder hingga halaman dan koneksi Firebase. File manifest web tidak dibahas karena tetap menggunakan konfigurasi template Flutter default.