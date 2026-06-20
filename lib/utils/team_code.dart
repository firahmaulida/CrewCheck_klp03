import 'dart:math';

/// Generate kode tim acak 6 karakter (huruf besar + angka).
/// Dipakai saat user membuat tim baru di CreateTeamPage.
String generateTeamCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // tanpa 0/O/1/I biar gak ambigu
  final rand = Random();
  return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
}