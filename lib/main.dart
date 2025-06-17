import 'package:flutter/material.dart';

void main() {
  runApp(const GymTrackApp());
}

class GymTrackApp extends StatelessWidget {
  const GymTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymTrack',
      home: Scaffold(
        appBar: AppBar(title: const Text('GymTrack')),
        body: const Center(child: Text('Bienvenido a GymTrack')),
      ),
    );
  }
}