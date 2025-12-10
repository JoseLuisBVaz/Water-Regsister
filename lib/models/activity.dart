import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String activityTypeId;
  final String activityName;
  final double quantity;
  final double litersUsed;
  final String category;
  final String icon;
  final String? unit;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.activityTypeId,
    required this.activityName,
    required this.quantity,
    required this.litersUsed,
    required this.category,
    required this.icon,
    this.unit,
    required this.timestamp,
  });

  // Convertir desde Firestore
  factory Activity.fromMap(Map<String, dynamic> map, String id) {
    return Activity(
      id: id,
      activityTypeId: map['activityTypeId'] ?? '',
      activityName: map['activityName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      litersUsed: (map['litersUsed'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      icon: map['icon'] ?? '💧',
      unit: map['unit'] ?? 'veces',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toMap() {
    return {
      'activityTypeId': activityTypeId,
      'activityName': activityName,
      'quantity': quantity,
      'litersUsed': litersUsed,
      'category': category,
      'icon': icon,
      'unit': unit,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
