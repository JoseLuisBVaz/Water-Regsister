class ActivityType {
  final String id;
  final String name;
  final double litersPerUnit;
  final String category;
  final String unit; // 'minutos', 'veces', 'cargas', etc.
  final String icon;

  ActivityType({
    required this.id,
    required this.name,
    required this.litersPerUnit,
    required this.category,
    required this.unit,
    required this.icon,
  });

  // Convertir desde Firestore
  factory ActivityType.fromMap(Map<String, dynamic> map, String id) {
    return ActivityType(
      id: id,
      name: map['name'] ?? '',
      litersPerUnit: (map['litersPerUnit'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      unit: map['unit'] ?? 'veces',
      icon: map['icon'] ?? '💧',
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'litersPerUnit': litersPerUnit,
      'category': category,
      'unit': unit,
      'icon': icon,
    };
  }
  
  // Sobreescribir equals y hashCode para comparación correcta en dropdown
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityType && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
