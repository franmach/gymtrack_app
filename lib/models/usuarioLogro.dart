class UsuarioLogro {
  final String usuarioId;
  final String logroId;

  UsuarioLogro({
    required this.usuarioId,
    required this.logroId,
  });

  factory UsuarioLogro.fromMap(Map<String, dynamic> map) => UsuarioLogro(
        usuarioId: map['usuario_id'] as String,
        logroId: map['logro_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'logro_id': logroId,
      };
}
