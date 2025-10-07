import 'package:intl/intl.dart';

/// Reduce la cantidad de puntos de una serie manteniendo la forma general.
/// Si hay menos o igual que maxPoints devuelve la lista original.
List<T> sampleSeries<T>(List<T> data, int maxPoints) {
  if (data.length <= maxPoints) return data;
  final step = (data.length / maxPoints).ceil();
  final out = <T>[];
  for (var i = 0; i < data.length; i += step) out.add(data[i]);
  if (out.isNotEmpty && out.last != data.last) out.add(data.last);
  return out;
}

/// Formatea etiquetas de fecha/strings para mostrar de forma compacta.
String compactLabel(String label, {bool short = false}) {
  // intenta parsear fecha ISO y formatear; si falla, trunca la cadena
  try {
    final d = DateTime.parse(label);
    return short ? DateFormat('dd/MM').format(d) : DateFormat('dd/MM/yyyy').format(d);
  } catch (_) {
    if (short && label.length > 8) return label.substring(0, 8) + '…';
    if (!short && label.length > 16) return label.substring(0, 16) + '…';
    return label;
  }
}