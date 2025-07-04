class UsuarioPermiso {
  final String usuarioId;
  final String permisoId;

  UsuarioPermiso({required this.usuarioId, required this.permisoId});

  factory UsuarioPermiso.fromMap(Map<String, dynamic> m) => UsuarioPermiso(
        usuarioId: m['usuario_id'] as String,
        permisoId: m['permiso_id'] as String,
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'permiso_id': permisoId,
      };
}