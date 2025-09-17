import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/advice_provider.dart';
import '../../models/educational_advice.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla que muestra consejos educativos por categoría (tabs).
/// Requiere provider `AdviceProvider` en el árbol de widgets.
class EducationalAdviceScreen extends StatefulWidget {
  final String? userId; // opcional: si null usa current user

  const EducationalAdviceScreen({Key? key, this.userId}) : super(key: key);

  @override
  _EducationalAdviceScreenState createState() => _EducationalAdviceScreenState();
}

class _EducationalAdviceScreenState extends State<EducationalAdviceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = ['Todos', 'Nutrición', 'Lesiones', 'Hábitos'];
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _userId = widget.userId ?? (FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Normaliza: minúsculas y remueve tildes/diacríticos comunes para comparar sin acentos.
  String _normalize(String s) {
    var out = s.toLowerCase().trim();
    final map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c'
    };
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    // eliminar caracteres no alfanuméricos salvo espacios
    out = out.replaceAll(RegExp(r'[^\w\s]', unicode: true), '');
    return out;
  }

  List<EducationalAdvice> _filterByTab(List<EducationalAdvice> list, int tabIndex) {
    if (tabIndex == 0) return list;
    final tabNorm = _normalize(_tabs[tabIndex]);
    return list.where((a) {
      final tipoNorm = _normalize(a.tipo);
      // usar contains para permitir "nutricion-avanzada" etc. si aplica
      return tipoNorm.contains(tabNorm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdviceProvider>(
      create: (_) => AdviceProvider(),
      child: Consumer<AdviceProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Consejos educativos'),
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    final provider = Provider.of<AdviceProvider>(context, listen: false);
                    try {
                      await provider.generateForUser(_userId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consejos generados correctamente')));
                    } catch (e) {
                      // Mensaje visible y diálogo para errores críticos
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo generar el consejo: $e')));
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('No se pudo generar consejos: $e'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
                          ],
                        ),
                      );
                    }
                  },
                  tooltip: 'Generar consejos (IA)',
                ),
              ],
            ),
            body: StreamBuilder<List<EducationalAdvice>>(
              stream: provider.streamAdvices(_userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (i) {
                    final list = _filterByTab(all, i);
                    if (list.isEmpty) {
                      return const Center(child: Text('No hay consejos disponibles.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (ctx, idx) {
                        final a = list[idx];
                        final fechaStr = DateFormat('dd/MM/yyyy').format(a.fecha);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(a.tipo.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Text(fechaStr, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(a.mensaje),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Chip(
                                      label: Text(a.fuente == 'ai' ? 'Generado por IA' : 'Manual (admin)'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }
}