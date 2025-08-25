import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:gymtrack_app/services/local_notification_store.dart';
import 'dart:math';

class ConfigNotificacionesScreen extends StatefulWidget {
  final String usuarioId;
  const ConfigNotificacionesScreen({super.key, required this.usuarioId});

  @override
  State<ConfigNotificacionesScreen> createState() =>
      _ConfigNotificacionesScreenState();
}

class _ConfigNotificacionesScreenState
    extends State<ConfigNotificacionesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'entrenamiento';
  String _mensaje = '';
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  Set<int> _diasSeleccionados = {};
  List<Map<String, dynamic>> _notificaciones = [];

  bool _motivacionalesActivadas = false; // CAMBIO
  final _store = LocalNotificationStore(); // CAMBIO

  final List<Map<String, dynamic>> _diasSemana = [
    {'id': 1, 'label': 'L'},
    {'id': 2, 'label': 'M'},
    {'id': 3, 'label': 'M'},
    {'id': 4, 'label': 'J'},
    {'id': 5, 'label': 'V'},
    {'id': 6, 'label': 'S'},
    {'id': 7, 'label': 'D'},
  ];

  final List<String> _frasesMotivacionales = [
    "¡No te rindas, cada día cuenta!",
    "Hoy es un gran día para entrenar.",
    "Tu esfuerzo de hoy es tu logro de mañana.",
    "¡Un paso más hacia tu meta!",
    "Entrena con constancia, los resultados llegan.",
    "La disciplina vence a la motivación.",
    "¡Hora de moverse, tu cuerpo lo agradecerá!",
    "Tu mejor inversión es en vos mismo.",
    "Cuidá tu cuerpo, es el único lugar que tenés para vivir.",
    "¡Vamos, que podés con esto y más!"
  ];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
    _motivacionalesActivadas = _store.areMotivationalEnabled(); // CAMBIO
    if (_motivacionalesActivadas) {
      _programarMotivacionales();
    }
  }

  void _cargarNotificaciones() {
    setState(() {
      _notificaciones = _store
          .listReminders()
          .where((n) => n['usuarioId'] == widget.usuarioId)
          .toList();
    });
  }

  Future<void> _guardarNotificacion() async {
    if (_formKey.currentState!.validate() && _horaSeleccionada != null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      if (_diasSeleccionados.isEmpty) {
        if (_fechaSeleccionada == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleccione una fecha si no repite')),
          );
          return;
        }

        final fechaHora = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
          _horaSeleccionada!.hour,
          _horaSeleccionada!.minute,
        );

        final noti = {
          'id': id,
          'usuarioId': widget.usuarioId,
          'tipo': _tipo,
          'mensaje': _mensaje,
          'programadaPara': fechaHora.toIso8601String(),
          'hora': _horaSeleccionada!.format(context),
          'diasSemana': <int>[],
        };

        await _store.upsertReminder(noti);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id.hashCode,
            channelKey: 'gymtrack_channel',
            title: _tipo.toUpperCase(),
            body: _mensaje,
          ),
          schedule: NotificationCalendar.fromDate(date: fechaHora),
        );
      } else {
        final noti = {
          'id': id,
          'usuarioId': widget.usuarioId,
          'tipo': _tipo,
          'mensaje': _mensaje,
          'hora': _horaSeleccionada!.format(context),
          'diasSemana': _diasSeleccionados.toList(),
        };

        await _store.upsertReminder(noti);

        for (final dia in _diasSeleccionados) {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: id.hashCode + dia,
              channelKey: 'gymtrack_channel',
              title: _tipo.toUpperCase(),
              body: _mensaje,
            ),
            schedule: NotificationCalendar(
              weekday: dia,
              hour: _horaSeleccionada!.hour,
              minute: _horaSeleccionada!.minute,
              second: 0,
              repeats: true,
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación guardada')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _fechaSeleccionada = null;
        _horaSeleccionada = null;
        _diasSeleccionados.clear();
        _mensaje = '';
      });
      _cargarNotificaciones();
    }
  }

  Future<void> _eliminarNotificacion(Map<String, dynamic> noti) async {
    await _store.deleteReminder(noti['id']);
    await AwesomeNotifications().cancel(noti['id'].hashCode);
    _cargarNotificaciones();
  }

  Future<void> _programarMotivacionales() async {
    final horas = [9, 15, 19];
    for (final h in horas) {
      final frase =
          _frasesMotivacionales[Random().nextInt(_frasesMotivacionales.length)];
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10000 + h,
          channelKey: 'gymtrack_channel',
          title: 'GymTrack',
          body: frase,
        ),
        schedule: NotificationCalendar(
          hour: h,
          minute: 0,
          second: 0,
          repeats: true,
        ),
      );
    }
  }

  Future<void> _cancelarMotivacionales() async {
    for (final h in [9, 15, 19]) {
      await AwesomeNotifications().cancel(10000 + h);
    }
  }

  void _toggleMotivacionales(bool value) async {
    setState(() => _motivacionalesActivadas = value);
    await _store.setMotivationalEnabled(value); // CAMBIO
    if (value) {
      _programarMotivacionales();
    } else {
      _cancelarMotivacionales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recibir frases motivacionales diarias'),
                Switch(
                  value: _motivacionalesActivadas,
                  onChanged: _toggleMotivacionales,
                ),
              ],
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'entrenamiento', child: Text('Entrenamiento')),
                      DropdownMenuItem(
                          value: 'alimentacion', child: Text('Alimentación')),
                      DropdownMenuItem(value: 'pago', child: Text('Pago')),
                      DropdownMenuItem(
                          value: 'motivacional', child: Text('Motivacional')),
                    ],
                    onChanged: (value) => setState(() => _tipo = value!),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese un mensaje' : null,
                    onChanged: (v) => _mensaje = v,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_horaSeleccionada == null
                            ? 'Sin hora seleccionada'
                            : _horaSeleccionada!.format(context)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _horaSeleccionada = picked);
                          }
                        },
                        child: const Text('Seleccionar Hora'),
                      ),
                    ],
                  ),
                  if (_diasSeleccionados.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Text(_fechaSeleccionada == null
                              ? 'Sin fecha seleccionada'
                              : DateFormat('dd/MM/yyyy')
                                  .format(_fechaSeleccionada!)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _fechaSeleccionada = picked);
                            }
                          },
                          child: const Text('Seleccionar Fecha'),
                        ),
                      ],
                    ),
                  Wrap(
                    spacing: 8,
                    children: _diasSemana.map((dia) {
                      final seleccionado =
                          _diasSeleccionados.contains(dia['id']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (seleccionado) {
                              _diasSeleccionados.remove(dia['id']);
                            } else {
                              _diasSeleccionados.add(dia['id']);
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dia['label'],
                            style: TextStyle(
                              color: seleccionado ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _guardarNotificacion,
                    child: const Text('Guardar Notificación'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _notificaciones.isEmpty
                  ? const Center(
                      child: Text('No hay notificaciones configuradas'))
                  : ListView.builder(
                      itemCount: _notificaciones.length,
                      itemBuilder: (context, index) {
                        final noti = _notificaciones[index];
                        final dias = (noti['diasSemana'] ?? []) as List;

                        return ListTile(
                          title: Text(noti['mensaje']),
                          subtitle: dias.isEmpty
                              ? Text(
                                  'Única - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(noti['programadaPara']))}')
                              : Text(
                                  'Recurrente - ${noti['hora']} - Días: ${dias.join(", ")}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarNotificacion(noti),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
