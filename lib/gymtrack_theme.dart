import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color blanco = Color(0xFFFFFFFF);
const Color negro = Color(0xFF000000);
const Color verdeFluor = Color(0xFF4CFF00);
const Color grisClaro = Color(0xFFa7a7a7);

final ThemeData gymTrackTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
  primaryColor: verdeFluor,
  colorScheme: ColorScheme.dark(
    primary: verdeFluor,
    onPrimary: negro,
    secondary: grisClaro,
    onSecondary: blanco,
    surface: negro,
    onSurface: blanco,
    background: const Color.fromARGB(255, 10, 10, 10),
    onBackground: blanco,
    error: const Color.fromARGB(255, 255, 17, 0),
    onError: blanco,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed) ||
            states.contains(MaterialState.hovered)) {
          return verdeFluor.withOpacity(0.85);
        }
        return verdeFluor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed) ||
            states.contains(MaterialState.hovered)) {
          return negro;
        }
        return negro;
      }),
      textStyle: MaterialStateProperty.all(
        GoogleFonts.rajdhani(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevation: MaterialStateProperty.all(8),
      shadowColor: MaterialStateProperty.all(
        verdeFluor.withAlpha(200),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: grisClaro.withOpacity(0.12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: grisClaro.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: verdeFluor.withOpacity(0.9), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: grisClaro.withOpacity(0.12)),
    ),
    labelStyle: GoogleFonts.rajdhani(color: blanco),
    floatingLabelStyle: GoogleFonts.rajdhani(color: verdeFluor),
    hintStyle: GoogleFonts.rajdhani(color: blanco.withOpacity(0.7)),
    prefixStyle: GoogleFonts.rajdhani(color: blanco),
    suffixStyle: GoogleFonts.rajdhani(color: blanco),
  ),
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
    bodyMedium: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
    labelLarge: GoogleFonts.rajdhani(fontSize: 18, color: blanco),
    headlineSmall: GoogleFonts.orbitron(
        fontSize: 24, fontWeight: FontWeight.bold, color: blanco),
    headlineMedium: GoogleFonts.orbitron(
        fontSize: 28, fontWeight: FontWeight.bold, color: blanco),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: GoogleFonts.orbitron(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: blanco,
    ),
    iconTheme: const IconThemeData(color: blanco),
  ),
  // Removed dropdownButtonTheme because it's unavailable in the current Flutter SDK;
  // use dropdownMenuTheme (Material 3) or apply styles directly to DropdownButton widgets.
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: const MenuStyle(
      // Esto aplica sólo a DropdownMenu (M3), no a DropdownButton.
      // Se deja por compatibilidad si migran a DropdownMenu.
    ),
    textStyle: GoogleFonts.rajdhani(color: blanco, fontSize: 16),
  ),
);
