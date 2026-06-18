import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color colorMerah = Color(0xFFE63629);
const Color colorKuning = Color(0xFFFFE56C);
const Color colorKrem = Color(0xFFFFF4B6);
const Color colorBg = Color(0xFFFFFAEE);
const Color colorBiru = Color(0xFF049DD8);

TextStyle crewCheckTitleStyle({double size = 65, Color color = colorMerah}) {
  return GoogleFonts.homenaje(color: color, fontSize: size);
}

TextStyle bodyTextStyle({double size = 18, Color color = Colors.black}) {
  return GoogleFonts.boogaloo(color: color, fontSize: size);
}
