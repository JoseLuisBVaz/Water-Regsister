import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecord {
  final String id;
  final DateTime date;
  final double totalLiters;
  final int activitiesCount;

  DailyRecord({
    required this.id,
    required this.date,
    required this.totalLiters,
    required this.activitiesCount,
  });

  // Convertir desde Firestore
  factory DailyRecord.fromMap(Map<String, dynamic> map, String id) {
    return DailyRecord(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      totalLiters: (map['totalLiters'] ?? 0).toDouble(),
      activitiesCount: map['activitiesCount'] ?? 0,
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalLiters': totalLiters,
      'activitiesCount': activitiesCount,
    };
  }

  // Obtener fecha sin hora (para agrupar por día)
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
