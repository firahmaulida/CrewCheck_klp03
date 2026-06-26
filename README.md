# CrewCheck: Aplikasi Manajemen Tim dan Monitoring Tugas

CrewCheck adalah aplikasi manajemen proyek berbasis mobile yang dirancang untuk mengoptimalkan koordinasi tim dan pemantauan tugas secara terpusat. Aplikasi ini mengadopsi model kode kelas unik untuk pembentukan tim secara dinamis, yang membagi peran pengguna menjadi pemimpin tim (Leader) dan anggota (Member).

## Deskripsi Proyek
Aplikasi ini dikembangkan sebagai solusi atas tantangan kolaborasi tim yang sering terhambat oleh kurangnya visibilitas terhadap progres pekerjaan. Melalui integrasi penyimpanan berbasis cloud, CrewCheck menyediakan platform di mana progres setiap individu dapat dipantau secara langsung, diskusi tim dapat dilakukan secara real-time, dan jadwal kerja dapat diatur secara sistematis.

## Tujuan Pengembangan
1. Memfasilitasi pembentukan dan pengelolaan kelompok kerja secara efisien melalui sistem kode unik.
2. Menyediakan mekanisme pemantauan progres tugas yang transparan bagi pemimpin tim.
3. Memusatkan komunikasi teknis antar anggota tim melalui fitur ruang obrolan terintegrasi.
4. Meningkatkan kedisiplinan tenggat waktu melalui visualisasi jadwal tugas mingguan.

## Daftar Fitur
1. **Sistem Autentikasi**: Fitur login dan pendaftaran akun yang terintegrasi dengan Firebase Authentication untuk keamanan data pengguna.
2. **Dashboard Summary**: Menampilkan statistik ringkasan tugas harian, mingguan, dan total tugas yang telah diselesaikan.
3. **Manajemen Tim**: Pemimpin tim dapat membuat proyek baru, menghasilkan kode unik, dan mendistribusikan daftar tugas kepada anggota.
4. **Kolaborasi Tim**: Anggota dapat bergabung ke dalam tim menggunakan kode referensi dan memperbarui status tugas secara mandiri.
5. **Jadwal dan Kalender**: Representasi visual jadwal kerja dalam format kalender horizontal untuk memudahkan identifikasi tenggat waktu.
6. **Ruang Obrolan (Chat)**: Fitur pesan instan real-time untuk koordinasi internal di dalam satu kelompok proyek.
7. **Checklist Progres**: Indikator persentase penyelesaian proyek berdasarkan tugas-tugas yang telah dikerjakan oleh anggota.

## Teknologi dan Komponen yang Digunakan
1. **Framework Utama**: Flutter SDK (versi 3.x)
2. **Bahasa Pemrograman**: Dart
3. **Backend Service**: Google Firebase
   - Firebase Authentication (Manajemen User)
   - Cloud Firestore (Database NoSQL)
4. **Library Tambahan**:
   - google_fonts: Implementasi tipografi Homenaje dan Boogaloo.
   - firebase_core: Integrasi utama layanan Firebase.
   - cloud_firestore: Sinkronisasi data real-time database.
5. **Arsitektur**: Mengikuti pola desain Material Design 3 dengan skema warna khusus (Red: #E63629, Yellow: #FFE56C, Cream: #FFF4B6).

## Struktur Database (Cloud Firestore)
1. **users**: Koleksi data profil pengguna yang mencakup username, email, dan nomor telepon.
2. **teams**: Koleksi utama data kelompok yang menyimpan nama proyek, deskripsi, kode akses, dan daftar ID anggota.
3. **tasks (Sub-koleksi)**: Folder data di dalam setiap dokumen tim yang menyimpan rincian tugas seperti judul, penanggung jawab, tanggal, dan status penyelesaian.
4. **messages (Sub-koleksi)**: Folder data di dalam setiap dokumen tim yang menyimpan riwayat pesan dan waktu pengiriman secara kronologis.

## Panduan Instalasi dan Pengoperasian
1. **Unduh Repositori**:
   ```bash
   git clone https://github.com/USERNAME_ANDA/crew_check.git
   ```
2. **Instalasi Paket Dependensi**:
   Jalankan perintah berikut pada terminal di dalam direktori proyek:
   ```bash
   flutter pub get
   ```
3. **Konfigurasi Firebase**:
   - Tempatkan file konfigurasi `google-services.json` pada direktori `android/app/`.
   - Pastikan API Key pada konfigurasi `FirebaseOptions` di file `lib/main.dart` telah sesuai dengan proyek Firebase Anda.
4. **Menjalankan Aplikasi**:
   ```bash
   flutter run
   ```

## Screenshot Tampilan Aplikasi
<img width="831" height="842" alt="image" src="https://github.com/user-attachments/assets/b2f6668a-739b-4379-b2f3-2776c16baac4" />

---

## Identitas Kelompok
1. **Firah Maulida** (2308107010034)
2. **Yuyun Nailufar** (2308107010066)

**Jurusan Informatika - Fakultas Matematika dan Ilmu Pengetahuan Alam**  
**Universitas Syiah Kuala**  
**2026**
