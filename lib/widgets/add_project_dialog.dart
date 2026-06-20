import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/pages/join_team_page.dart';
import 'package:crew_check/pages/create_team_page.dart';

/// Popup "Tambah Projek" — dipanggil lewat showAddProjectDialog(context).
/// Menampilkan dua opsi: Gabung ke tim atau Buat tim baru.
void showAddProjectDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) {
      return Dialog(
        backgroundColor: colorBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Tambah Projek',
                  style: GoogleFonts.boogaloo(
                    color: colorMerah,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                context: context,
                icon: Icons.person_add_alt_1,
                label: 'Gabung ke tim',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinTeamPage()),
                  );
                },
              ),
              const Divider(height: 1),
              _buildOptionTile(
                context: context,
                icon: Icons.group_add,
                label: 'Buat tim',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTeamPage()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOptionTile({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.boogaloo(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}