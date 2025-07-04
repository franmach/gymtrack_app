class MensajeDestinatario {
  final String mensajeId;
  final String usuarioId;

  MensajeDestinatario({
    required this.mensajeId,
    required this.usuarioId,
  });

  factory MensajeDestinatario.fromMap(Map<String, dynamic> map) => MensajeDestinatario(
        mensajeId: map['mensaje_id'] as String,
        usuarioId: map['usuario_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        'mensaje_id': mensajeId,
        'usuario_id': usuarioId,
      };
}