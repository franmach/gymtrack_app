class ContenidoEducativo {
  final String id;
  final String titulo;
  final String tipo;
  final String categoria;
  final String url; 

  ContenidoEducativo({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.categoria,
    required this.url,
  });

  factory ContenidoEducativo.fromMap(Map<String, dynamic> map) => ContenidoEducativo(
        id: map['id'] as String,
        titulo: map['titulo'] as String,
        tipo: map['tipo'] as String,
        categoria: map['categoria'] as String,
        url: map['url'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'tipo': tipo,
        'categoria': categoria,
        'url': url,
      };
}