class codigos_gimnasio {
  String? gimnasioId;
  String? codigo;
  String? descripcion;
  String? estado;
  DateTime? createdBy;
  DateTime? createdAt;
  DateTime? expiresAt;
  int? maxUses;
  int? usedCount;
  List<String>? usedBy;
  bool? active;

  codigos_gimnasio({this.gimnasioId, this.codigo, this.descripcion, this.estado, this.createdBy, this.createdAt, this.expiresAt, this.maxUses, this.usedCount, this.usedBy, this.active});

  codigos_gimnasio.fromJson(Map<String, dynamic> json) {
    gimnasioId = json['gimnasioId'];
    codigo = json['codigo'];
    descripcion = json['descripcion'];
    estado = json['estado'];
    createdBy = DateTime.parse(json['createdBy']);
    createdAt = DateTime.parse(json['createdAt']);
    expiresAt = DateTime.parse(json['expiresAt']);
    maxUses = json['maxUses'];
    usedCount = json['usedCount'];
    usedBy = List<String>.from(json['usedBy']);
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gimnasioId'] = gimnasioId;
    data['codigo'] = codigo;
    data['descripcion'] = descripcion;
    data['estado'] = estado;
    data['createdBy'] = createdBy?.toIso8601String();
    data['createdAt'] = createdAt?.toIso8601String();
    data['expiresAt'] = expiresAt?.toIso8601String();
    data['maxUses'] = maxUses;
    data['usedCount'] = usedCount;
    data['usedBy'] = usedBy;
    data['active'] = active;
    return data;
  }
}