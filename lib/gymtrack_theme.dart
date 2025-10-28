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
    // Usado por InputDecorator/DropdownButtonFormField
    titleMedium: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
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
);

class AppTheme {
  static const _radius = 16.0;

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
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
      // Usado por InputDecorator/DropdownButtonFormField
      titleMedium: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
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
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      contentTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      // backgroundColor lo dejamos null: cada tipo de mensaje lo setea AppMessenger
      actionTextColor: Colors.black,
    ),
  );

  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
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
      // Usado por InputDecorator/DropdownButtonFormField
      titleMedium: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
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
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      contentTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}
