import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_type.dart';
import '../models/activity.dart';
import '../models/daily_record.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ID de usuario autenticado
  String get userId => _auth.currentUser?.uid ?? 'anonymous';

  // ========== ACTIVITY TYPES (Catálogo) ==========
  
  /// Obtener todos los tipos de actividades
  Future<List<ActivityType>> getActivityTypes() async {
    try {
      final snapshot = await _firestore.collection('activity_types').get();
      return snapshot.docs.map((doc) => ActivityType.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de actividades: $e');
    }
  }

  /// Stream de tipos de actividades
  Stream<List<ActivityType>> activityTypesStream() {
    return _firestore.collection('activity_types').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => ActivityType.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  // ========== DAILY RECORDS ==========
  
  /// Obtener o crear registro del día actual (previene duplicados)
  Future<String> getTodayRecordId() async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final recordsRef = _firestore.collection('users').doc(userId).collection('daily_records');
      
      // Buscar registro existente
      final query = await recordsRef.where('dateKey', isEqualTo: dateKey).limit(1).get();
      
      if (query.docs.isNotEmpty) {
        print('📋 Registro existente encontrado: ${query.docs.first.id}');
        return query.docs.first.id;
      }
      
      // Crear nuevo registro usando documento con ID del dateKey para evitar duplicados
      final docRef = recordsRef.doc(dateKey);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        print('📋 Registro con ID dateKey ya existe: ${docRef.id}');
        return docRef.id;
      }
      
      await docRef.set({
        'date': Timestamp.fromDate(DateTime(today.year, today.month, today.day)),
        'dateKey': dateKey,
        'totalLiters': 0.0,
        'activitiesCount': 0,
      });
      
      print('✅ Nuevo registro creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error en getTodayRecordId: $e');
      rethrow;
    }
  }

  /// Obtener registros diarios (últimos N días)
  Future<List<DailyRecord>> getDailyRecords({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => DailyRecord.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Error al obtener registros diarios: $e');
    }
  }

  /// Stream de registro del día actual
  Stream<DailyRecord?> todayRecordStream() async* {
    final recordId = await getTodayRecordId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_records')
        .doc(recordId)
        .snapshots()
        .map((doc) => doc.exists ? DailyRecord.fromMap(doc.data()!, doc.id) : null);
  }

  // ========== ACTIVITIES (CRUD Completo) ==========
  
  /// **CONSULTA (READ)** - Obtener actividades de un día específico
  Future<List<Activity>> getActivitiesForDay(String recordId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Activity.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Error al obtener actividades: $e');
    }
  }

  /// Stream de actividades del día actual
  Stream<List<Activity>> todayActivitiesStream() async* {
    final recordId = await getTodayRecordId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_records')
        .doc(recordId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Activity.fromMap(doc.data(), doc.id)).toList());
  }

  /// **INSERCIÓN (CREATE)** - Agregar nueva actividad
  Future<void> addActivity({
    required String activityTypeId,
    required String activityName,
    required double quantity,
    required double litersPerUnit,
    required String category,
    required String icon,
    required String unit,
  }) async {
    try {
      final recordId = await getTodayRecordId();
      final litersUsed = quantity * litersPerUnit;
      
      final activity = Activity(
        id: '',
        activityTypeId: activityTypeId,
        activityName: activityName,
        quantity: quantity,
        litersUsed: litersUsed,
        category: category,
        icon: icon,
        unit: unit,
        timestamp: DateTime.now(),
      );
      
      // Agregar actividad
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .add(activity.toMap());
      
      // Actualizar totales del día
      await _updateDailyTotal(recordId);
      
      // Actualizar consumo global
      await updateGlobalConsumption(litersUsed);
    } catch (e) {
      throw Exception('Error al agregar actividad: $e');
    }
  }

  /// **ACTUALIZACIÓN (UPDATE)** - Editar actividad existente
  Future<void> updateActivity({
    required String recordId,
    required String activityId,
    required double quantity,
    required double litersPerUnit,
  }) async {
    try {
      // Obtener el valor anterior para ajustar el global
      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .doc(activityId)
          .get();
      
      final oldLiters = activityDoc.exists ? (activityDoc.data()?['litersUsed'] ?? 0.0).toDouble() : 0.0;
      final newLiters = quantity * litersPerUnit;
      final difference = newLiters - oldLiters;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .doc(activityId)
          .update({
        'quantity': quantity,
        'litersUsed': newLiters,
      });
      
      // Actualizar totales del día
      await _updateDailyTotal(recordId);
      
      // Ajustar consumo global con la diferencia
      if (difference != 0) {
        await updateGlobalConsumption(difference);
      }
    } catch (e) {
      throw Exception('Error al actualizar actividad: $e');
    }
  }

  /// **ELIMINACIÓN (DELETE)** - Eliminar actividad
  Future<void> deleteActivity(String recordId, String activityId) async {
    try {
      // Obtener los litros antes de eliminar
      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .doc(activityId)
          .get();
      
      final litersToSubtract = activityDoc.exists ? (activityDoc.data()?['litersUsed'] ?? 0.0).toDouble() : 0.0;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .doc(activityId)
          .delete();
      
      // Actualizar totales del día
      await _updateDailyTotal(recordId);
      
      // Decrementar consumo global
      if (litersToSubtract > 0) {
        await updateGlobalConsumption(-litersToSubtract);
      }
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  /// Eliminar registro diario completo
  Future<void> deleteDailyRecord(String recordId) async {
    try {
      // Eliminar todas las actividades primero
      final activities = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .collection('activities')
          .get();
      
      for (var doc in activities.docs) {
        await doc.reference.delete();
      }
      
      // Eliminar el registro diario
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar registro diario: $e');
    }
  }

  // ========== UTILIDADES ==========
  
  /// Recalcular totales del día
  Future<void> _updateDailyTotal(String recordId) async {
    try {
      final activities = await getActivitiesForDay(recordId);
      
      final totalLiters = activities.fold<double>(0.0, (total, activity) => total + activity.litersUsed);
      final activitiesCount = activities.length;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordId)
          .update({
        'totalLiters': totalLiters,
        'activitiesCount': activitiesCount,
      });
    } catch (e) {
      throw Exception('Error al actualizar totales: $e');
    }
  }
  
  // ========== CONSUMO GLOBAL ==========
  
  /// Actualizar el consumo global del día actual (suma de todos los usuarios)
  Future<void> updateGlobalConsumption(double litersToAdd) async {
    try {
      // Obtener la fecha del día actual como ID del documento
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final globalRef = _firestore.collection('global_stats').doc(dateKey);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(globalRef);
        
        if (!snapshot.exists) {
          // Crear el documento si no existe
          transaction.set(globalRef, {
            'totalLiters': litersToAdd,
            'date': Timestamp.fromDate(DateTime(today.year, today.month, today.day)),
            'dateKey': dateKey,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
        } else {
          // Incrementar el total
          final currentTotal = (snapshot.data()?['totalLiters'] ?? 0.0).toDouble();
          transaction.update(globalRef, {
            'totalLiters': currentTotal + litersToAdd,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error al actualizar consumo global: $e');
      // No lanzar error para no afectar la operación principal
    }
  }
  
  /// Obtener el consumo global del día actual
  Future<double> getGlobalConsumption() async {
    try {
      // Obtener la fecha del día actual
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final snapshot = await _firestore.collection('global_stats').doc(dateKey).get();
      
      if (snapshot.exists) {
        return (snapshot.data()?['totalLiters'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error al obtener consumo global: $e');
      return 0.0;
    }
  }

  /// Obtener el consumo global total (todos los tiempos)
  Future<double> getTotalGlobalConsumption() async {
    try {
      final snapshot = await _firestore.collection('global_stats').get();
      double total = 0.0;
      
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalLiters'] ?? 0.0).toDouble();
      }
      
      return total;
    } catch (e) {
      print('Error al obtener consumo global total: $e');
      return 0.0;
    }
  }
  
  /// Stream del consumo global del día actual
  Stream<double> globalConsumptionStream() {
    // Obtener la fecha del día actual
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _firestore
        .collection('global_stats')
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return (snapshot.data()?['totalLiters'] ?? 0.0).toDouble();
      }
      return 0.0;
    });
  }

  /// Stream del consumo global total (todos los tiempos)
  Stream<double> totalGlobalConsumptionStream() {
    return _firestore
        .collection('global_stats')
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalLiters'] ?? 0.0).toDouble();
      }
      return total;
    });
  }  /// Obtener estadísticas (última semana/mes)
  Future<Map<String, dynamic>> getStatistics({int days = 7}) async {
    try {
      final records = await getDailyRecords(days: days);
      
      if (records.isEmpty) {
        return {
          'totalLiters': 0.0,
          'averagePerDay': 0.0,
          'maxDay': null,
          'minDay': null,
          'daysWithData': 0,
        };
      }
      
      final totalLiters = records.fold<double>(0.0, (total, record) => total + record.totalLiters);
      final averagePerDay = totalLiters / records.length;
      
      final maxRecord = records.reduce((a, b) => a.totalLiters > b.totalLiters ? a : b);
      final minRecord = records.reduce((a, b) => a.totalLiters < b.totalLiters ? a : b);
      
      return {
        'totalLiters': totalLiters,
        'averagePerDay': averagePerDay,
        'maxDay': maxRecord,
        'minDay': minRecord,
        'daysWithData': records.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
