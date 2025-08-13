import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color blanco = Color(0xFFFFFFFF);
const Color negro = Color(0xFF000000);
const Color verdeFluor = Color(0xFF4CFF00);
const Color grisClaro = Color(0xFFa7a7a7);

final ThemeData gymTrackTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
  primaryColor: verdeFluor,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: verdeFluor,
    onPrimary: negro,
    secondary: grisClaro,
    onSecondary: negro,
    surface:negro, 
    onSurface: blanco,
    error: const Color.fromARGB(255, 255, 17, 0),
    onError: blanco,
  ),
  useMaterial3: true,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
          return negro; // color más claro en hover
        }
        return verdeFluor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)  || states.contains(WidgetState.pressed)) {
          return verdeFluor; // color más claro en hover
        }
        return negro;
      }),
      textStyle: WidgetStateProperty.all(
      GoogleFonts.rajdhani(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevation: WidgetStateProperty.all(8),
      shadowColor: WidgetStateProperty.all(
        verdeFluor.withAlpha(204),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: grisClaro, // Fondo gris para los TextField
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: grisClaro),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: grisClaro, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: grisClaro),
    ),
    labelStyle: GoogleFonts.rajdhani(color: negro),
  floatingLabelStyle: GoogleFonts.rajdhani(color: blanco),
  hintStyle: GoogleFonts.rajdhani(color: blanco),
  prefixStyle: GoogleFonts.rajdhani(color: blanco),
  suffixStyle: GoogleFonts.rajdhani(color: blanco),
  ),
  textTheme: TextTheme(
  bodyMedium: GoogleFonts.rajdhani(fontSize: 16, color: blanco),
  labelLarge: GoogleFonts.rajdhani(fontSize: 18, color: blanco),
  headlineSmall: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: blanco),
  headlineMedium: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, color: blanco),
),

  appBarTheme: AppBarTheme(

  elevation: 0,
  titleTextStyle: GoogleFonts.orbitron(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: const Color.fromARGB(255, 255, 255, 255),
  ),
),
);
