import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/add_project_dialog.dart';

Widget buildTextField({
  required String hint,
  required IconData icon,
  bool isPassword = false,
  bool isObscure = false,
  VoidCallback? onToggle,
  TextEditingController? controller,
}) {
  return TextField(
    controller: controller,
    obscureText: isPassword ? isObscure : false,
    style: GoogleFonts.boogaloo(),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: colorMerah),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: colorMerah,
              ),
              onPressed: onToggle,
            )
          : null,
      filled: true,
      fillColor: colorKuning,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget buildButton(String text, Color color, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        text,
        style: GoogleFonts.boogaloo(color: Colors.white, fontSize: 24),
      ),
    ),
  );
}

Widget buildSocialButton(String label, Color bg, Color textCol, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: textCol, size: 30),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.boogaloo(color: textCol, fontSize: 18)),
      ],
    ),
  );
}

BottomAppBar buildBottomNavBar(BuildContext context) {
  final String currentRoute =
      ModalRoute.of(context)?.settings.name ?? '/dashboard';

  Color iconColor(String route) =>
      currentRoute == route ? colorMerah : Colors.grey;

  return BottomAppBar(
    color: Colors.white,
    shape: const CircularNotchedRectangle(),
    notchMargin: 6.0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.home, color: iconColor('/dashboard')),
          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
        ),
        IconButton(
          icon: Icon(Icons.calendar_month, color: iconColor('/schedule')),
          onPressed: () => Navigator.pushNamed(context, '/schedule'),
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: Icon(Icons.chat, color: iconColor('/chat')),
          onPressed: () => Navigator.pushNamed(context, '/chat'),
        ),
        IconButton(
          icon: Icon(Icons.person, color: iconColor('/profile')),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    ),
  );
}

FloatingActionButton buildAddFab(BuildContext context) {
  return FloatingActionButton(
    onPressed: () => showAddProjectDialog(context),
    backgroundColor: colorMerah,
    child: const Icon(Icons.add, color: Colors.white),
  );
}