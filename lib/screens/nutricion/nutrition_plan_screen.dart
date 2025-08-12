import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Servicios y modelos
import 'package:gymtrack_app/services/nutrition_ai_service.dart';
import 'package:gymtrack_app/models/comidaPlanItem.dart';
import 'package:gymtrack_app/models/planAlimenticio.dart';

class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({Key? key}) : super(key: key);

  @override
  _NutritionPlanScreenState createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Servicio de IA para generar planes
  late final NutritionAIService _aiService;

  // Preferencias del usuario
  bool isVegetarian = false;
  bool isVegan = false;
  List<String> excludedFoods = [];
  String _newExcluded = '';

  // Datos del plan semanal (agrupado por día)
  Map<String, List<ComidaPlanItem>> weeklyPlan = {};

  // Datos del perfil del usuario
  Map<String, dynamic> userProfile = {};

  // Estado de carga
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _aiService = Provider.of<NutritionAIService>(context, listen: false);
    _loadResources();
  }

  /// Carga inicial de recursos: perfil y último plan
  Future<void> _loadResources() async {
    await Future.wait([
      _loadUserProfile(),
      _loadExistingPlan(),
    ]);
  }

  /// Cargar los datos del perfil de Firestore
  Future<void> _loadUserProfile() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userProfile = doc.data()!;
      });
    }
  }

  /// Cargar el último plan guardado en Firestore
  Future<void> _loadExistingPlan() async {
    final uid = _auth.currentUser!.uid;

    // Buscar el último plan para el usuario actual
    final snapshot = await _firestore
        .collection('nutritionPlans')
        .where('usuarioId', isEqualTo: uid)
        .orderBy('fechaCreacion', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final plan = PlanAlimenticio.fromMap(snapshot.docs.first.data());

      setState(() {
        isVegetarian = plan.isVegetarian;
        isVegan = plan.isVegan;
        excludedFoods = List.from(plan.excludedFoods);
        weeklyPlan = {
          for (var item in plan.weeklyPlan)
            item.day:
                plan.weeklyPlan.where((e) => e.day == item.day).toList()
        };
      });
    }
  }

  /// Generar un nuevo plan con IA y guardarlo automáticamente
  Future<void> _generatePlan() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;

      // Generar usando IA
      final items = await _aiService.generateWeeklyPlan(
        usuarioId: uid,
        vegetarian: isVegetarian,
        vegan: isVegan,
        excludedFoods: excludedFoods,
        perfil: userProfile,
      );

      // Agrupar por día
      setState(() {
        weeklyPlan = {
          for (var item in items)
            item.day: items.where((e) => e.day == item.day).toList()
        };
      });

      // Guardar en Firestore automáticamente
      await _savePlan();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar plan: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Guardar el plan actual en Firestore
  Future<void> _savePlan() async {
    final uid = _auth.currentUser!.uid;

    // Usamos el UID como ID de documento para que siempre se sobreescriba el plan actual
    final docRef = _firestore.collection('nutritionPlans').doc(uid);

    final plan = PlanAlimenticio(
      id: docRef.id,
      usuarioId: uid,
      fechaCreacion: DateTime.now(),
      objetivo: userProfile['objetivo'] ?? '',
      esActual: true,
      isVegetarian: isVegetarian,
      isVegan: isVegan,
      excludedFoods: excludedFoods,
      weeklyPlan: weeklyPlan.values.expand((e) => e).toList(),
    );

    await docRef.set(plan.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan guardado exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Alimenticio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preferencias
                    const Text(
                      'Preferencias',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      title: const Text('Vegetariano'),
                      value: isVegetarian,
                      onChanged: (v) => setState(() {
                        isVegetarian = v;
                        if (v) isVegan = false;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Vegano'),
                      value: isVegan,
                      onChanged: (v) => setState(() {
                        isVegan = v;
                        if (v) isVegetarian = false;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Excluir alimentos
                    const Text(
                      'Excluir alimentos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                                hintText: 'Agregar alimento'),
                            onChanged: (v) => _newExcluded = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_newExcluded.trim().isNotEmpty) {
                              setState(() {
                                excludedFoods.add(_newExcluded.trim());
                                _newExcluded = '';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: excludedFoods
                          .map((e) => Chip(
                                label: Text(e),
                                onDeleted: () => setState(
                                    () => excludedFoods.remove(e)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Botón de generación con IA
                    Center(
                      child: ElevatedButton(
                        onPressed: _generatePlan,
                        child: const Text('Generar plan con IA'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mostrar plan si existe
                    if (weeklyPlan.isNotEmpty) ...[
                      const Text(
                        'Plan Semanal',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...weeklyPlan.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            ...entry.value.map((item) => ListTile(
                                title: Text(item.comida.nombre),
                                subtitle: Text(
                                  '${item.comida.macros.proteinGrams}g proteína • '
                                  '${item.comida.macros.calories.toStringAsFixed(0)} kcal • '
                                  '${item.portion} porción'
                                  '${item.tipo.isNotEmpty ? ' • ${item.tipo}' : ''}'
                                ),
                              )),
                          ],
                        );
                      }).toList(),

                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _savePlan,
                          child: const Text('Guardar plan'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
