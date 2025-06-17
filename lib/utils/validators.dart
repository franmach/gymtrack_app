class Validators {
  static String? validarEmail(String? value) {
    if (value == null || !value.contains('@')) return 'Correo inválido';
    return null;
  }

  static String? validarPassword(String? value) {
    if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}