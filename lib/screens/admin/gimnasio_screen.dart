import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/gimnasio.dart';

class GimnasioScreen extends StatefulWidget {
  const GimnasioScreen({super.key});

  @override
  State<GimnasioScreen> createState() => _GimnasioScreenState();
}

class _GimnasioScreenState extends State<GimnasioScreen> {
  Gimnasio? gimnasio;
  bool cargando = true;
  String? diaSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarGimnasio();
  }

  Future<void> _cargarGimnasio() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gimnasios')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          gimnasio = Gimnasio.fromMap(data);
          cargando = false;
        });
      } else {
        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      print('Error al cargar gimnasio: $e');
      setState(() {
        cargando = false;
      });
    }
  }

  List<String> _diasDisponibles() {
    final todos = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return todos.where((d) => !gimnasio!.dias_abiertos.contains(d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Gimnasio')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : gimnasio == null
              ? const Center(child: Text('No hay gimnasio registrado.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        TextFormField(
                          initialValue: gimnasio!.nombre,
                          decoration:
                              const InputDecoration(labelText: 'Nombre'),
                          onChanged: (valor) {
                            setState(() {
                              gimnasio = gimnasio!.copyWith(nombre: valor);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Horario
                        TextFormField(
                          initialValue: gimnasio!.apertura,
                          decoration:
                              const InputDecoration(labelText: 'Apertura'),
                          onChanged: (valor) {
                            setState(() {
                              gimnasio = gimnasio!.copyWith(apertura: valor);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: gimnasio!.cierre,
                          decoration:
                              const InputDecoration(labelText: 'Cierre'),
                          onChanged: (valor) {
                            setState(() {
                              gimnasio = gimnasio!.copyWith(cierre: valor);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Equipamiento
                        const Text('Equipamiento',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: gimnasio!.equipamiento.map((item) {
                            return Chip(
                              label: Text(item),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  gimnasio = gimnasio!.copyWith(
                                    equipamiento:
                                        List.from(gimnasio!.equipamiento)
                                          ..remove(item),
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                        TextField(
                          decoration: const InputDecoration(
                              labelText: 'Agregar equipamiento'),
                          onSubmitted: (valor) {
                            if (valor.isEmpty) return;
                            setState(() {
                              final nuevaLista =
                                  List<String>.from(gimnasio!.equipamiento)
                                    ..add(valor);
                              gimnasio =
                                  gimnasio!.copyWith(equipamiento: nuevaLista);
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Días abiertos
                        const Text('Días abiertos',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: gimnasio!.dias_abiertos.map((dia) {
                            final dias =
                                List<String>.from(gimnasio!.dias_abiertos);
                            final esUltimo = dias.length == 1;

                            return Chip(
                              label: Text(dia),
                              deleteIcon:
                                  esUltimo ? null : const Icon(Icons.close),
                              onDeleted: esUltimo
                                  ? null
                                  : () {
                                      setState(() {
                                        diaSeleccionado =
                                            null; // importante: antes de modificar la lista
                                        final nuevaLista = List<String>.from(
                                            gimnasio!.dias_abiertos)
                                          ..remove(dia);
                                        gimnasio = gimnasio!.copyWith(
                                            dias_abiertos: nuevaLista);
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),

// Dropdown para agregar días
                        _diasDisponibles().isEmpty
                            ? const Text('Todos los días ya están agregados.')
                            : DropdownButtonFormField<String>(
                                value:
                                    _diasDisponibles().contains(diaSeleccionado)
                                        ? diaSeleccionado
                                        : null,
                                decoration: const InputDecoration(
                                    labelText: 'Agregar día'),
                                items: _diasDisponibles()
                                    .map((dia) => DropdownMenuItem(
                                        value: dia, child: Text(dia)))
                                    .toList(),
                                onChanged: (valor) {
                                  if (valor == null) return;
                                  setState(() {
                                    final nuevaLista = List<String>.from(
                                        gimnasio!.dias_abiertos)
                                      ..add(valor);
                                    gimnasio = gimnasio!
                                        .copyWith(dias_abiertos: nuevaLista);
                                    diaSeleccionado = null;
                                  });
                                },
                              ),

                        // Guardar
                        ElevatedButton(
                          onPressed: _guardarCambios,
                          child: const Text('Guardar cambios'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _guardarCambios() async {
    try {
      await FirebaseFirestore.instance
          .collection('gimnasios')
          .doc('gimnasio_point')
          .set(gimnasio!.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      print('Error al guardar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  }
}
