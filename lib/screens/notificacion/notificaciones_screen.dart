import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/notificacion.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Plugin de notificaciones (usa el inicializado en main.dart)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ConfigNotificacionesScreen extends StatefulWidget {
  final String usuarioId;

  const ConfigNotificacionesScreen({super.key, required this.usuarioId});

  @override
  _ConfigNotificacionesScreenState createState() =>
      _ConfigNotificacionesScreenState();
}

class _ConfigNotificacionesScreenState
    extends State<ConfigNotificacionesScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'entrenamiento';
  String _mensaje = '';
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  // --- Selección de fecha ---
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  // --- Selección de hora ---
  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  // --- Guardar en Firestore y programar notificación local ---
  Future<void> _guardarNotificacion() async {
    if (_formKey.currentState!.validate() &&
        _fechaSeleccionada != null &&
        _horaSeleccionada != null) {
      final DateTime fechaHora = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      final id =
          FirebaseFirestore.instance.collection('notificaciones').doc().id;

      final noti = Notificacion(
        id: id,
        usuarioId: widget.usuarioId,
        tipo: _tipo,
        mensaje: _mensaje,
        programadaPara: fechaHora,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('notificaciones')
          .doc(id)
          .set(noti.toMap());

      // Programar notificación local
      await _programarNotificacionLocal(noti);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación guardada y programada')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _fechaSeleccionada = null;
        _horaSeleccionada = null;
      });
    }
  }

  // --- Programación local ---
  Future<void> _programarNotificacionLocal(Notificacion noti) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      noti.hashCode,
      noti.tipo.toUpperCase(),
      noti.mensaje,
      tz.TZDateTime.from(noti.programadaPara, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_notificaciones',
          'Notificaciones GymTrack',
          channelDescription: 'Recordatorios y mensajes motivacionales',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // --- Eliminar notificación ---
  Future<void> _eliminarNotificacion(String id) async {
    await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificación eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Formulario ---
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
                      DropdownMenuItem(
                          value: 'motivacional', child: Text('Motivacional')),
                    ],
                    onChanged: (value) => setState(() => _tipo = value!),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Ingrese un mensaje'
                        : null,
                    onChanged: (value) => _mensaje = value,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_fechaSeleccionada == null
                            ? 'Sin fecha seleccionada'
                            : DateFormat('dd/MM/yyyy')
                                .format(_fechaSeleccionada!)),
                      ),
                      TextButton(
                        onPressed: _seleccionarFecha,
                        child: const Text('Seleccionar Fecha'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_horaSeleccionada == null
                            ? 'Sin hora seleccionada'
                            : _horaSeleccionada!.format(context)),
                      ),
                      TextButton(
                        onPressed: _seleccionarHora,
                        child: const Text('Seleccionar Hora'),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _guardarNotificacion,
                    child: const Text('Guardar Notificación'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Notificaciones guardadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // --- Listado desde Firestore ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notificaciones')
                    .where('usuarioId', isEqualTo: widget.usuarioId)
                    .orderBy('programada_para')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('No hay notificaciones configuradas'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final noti = Notificacion.fromMap(
                          docs[index].data() as Map<String, dynamic>);
                      return ListTile(
                        title: Text(noti.mensaje),
                        subtitle: Text(
                            '${noti.tipo} - ${DateFormat('dd/MM/yyyy HH:mm').format(noti.programadaPara)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarNotificacion(noti.id),
                        ),
                      );
                    },
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
