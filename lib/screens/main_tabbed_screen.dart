import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/screens/contenido_edu/educational_advice_screen.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/perfil/perfil_screen.dart';
import '../screens/session/session_screen.dart';
import '../screens/session/day_selection_screen.dart';
import '../screens/nutricion/nutrition_plan_screen.dart';
import '../services/firestore_routine_service.dart';

class MainTabbedScreen extends StatefulWidget {
  const MainTabbedScreen({super.key});

  @override
  State<MainTabbedScreen> createState() => _MainTabbedScreenState();
}

class _MainTabbedScreenState extends State<MainTabbedScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  final List<String> _titles = ['Inicio', 'Educativo', 'Entrenar', 'Comidas', 'Perfil'];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    _pages = [
      const DashboardScreen(), // Inicio
      const EducationalAdviceScreen(), // Contenido Educativo
      DaySelectionScreen(
        service: FirestoreRoutineService(),
        userId: uid,
      ), // Entrenar
      const NutritionPlanScreen(), // Comidas
      const PerfilScreen(), // Perfil
    ];
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              showUnselectedLabels: true,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              onTap: _onTabChanged,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_online_outlined),
                  activeIcon: Icon(Icons.book_online),
                  label: 'Educativo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_outlined),
                  activeIcon: Icon(Icons.fitness_center),
                  label: 'Entrenar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  activeIcon: Icon(Icons.restaurant_menu),
                  label: 'Comidas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}