import 'package:flutter/material.dart';
import '../models/activity_type.dart';
import '../models/activity.dart';
import '../models/daily_record.dart';
import '../services/firebase_service.dart';

class WaterConsumptionProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Estado
  List<ActivityType> _activityTypes = [];
  List<Activity> _todayActivities = [];
  DailyRecord? _todayRecord;
  double _globalConsumption = 0.0;
  double _totalGlobalConsumption = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ActivityType> get activityTypes => _activityTypes;
  List<Activity> get todayActivities => _todayActivities;
  DailyRecord? get todayRecord => _todayRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get globalConsumption => _globalConsumption;
  double get totalGlobalConsumption => _totalGlobalConsumption;
  
  // Calcular litros desde las actividades directamente
  double get totalLitersToday {
    return _todayActivities.fold<double>(0.0, (sum, activity) => sum + activity.litersUsed);
  }
  int get activitiesCountToday => _todayActivities.length;

  // ========== INICIALIZACIÓN ==========

  /// Cargar datos iniciales
  Future<void> initialize() async {
    print('🔄 Inicializando provider...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cargar tipos de actividades
      print('📋 Cargando tipos de actividades...');
      _activityTypes = await _firebaseService.getActivityTypes();
      print('✅ ${_activityTypes.length} tipos de actividades cargados');
      
      // Cargar actividades de hoy
      print('📅 Obteniendo registro del día...');
      final recordId = await _firebaseService.getTodayRecordId();
      print('✅ Record ID: $recordId');
      
      _todayActivities = await _firebaseService.getActivitiesForDay(recordId);
      print('✅ ${_todayActivities.length} actividades de hoy cargadas');
      print('💧 Total litros calculados: $totalLitersToday');
      
      // Cargar consumo global
      _globalConsumption = await _firebaseService.getGlobalConsumption();
      print('🌍 Consumo global: $_globalConsumption L');
      
      // Cargar consumo global total
      _totalGlobalConsumption = await _firebaseService.getTotalGlobalConsumption();
      print('🌍 Consumo global total: $_totalGlobalConsumption L');
      
      _isLoading = false;
      print('✅ Inicialización completada');
      notifyListeners();
    } catch (e) {
      print('❌ Error en initialize: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Escuchar cambios en tiempo real
  void listenToTodayActivities() {
    _firebaseService.todayActivitiesStream().listen((activities) {
      _todayActivities = activities;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });

    _firebaseService.todayRecordStream().listen((record) {
      _todayRecord = record;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
    
    // Escuchar cambios en consumo global del día
    _firebaseService.globalConsumptionStream().listen((consumption) {
      _globalConsumption = consumption;
      notifyListeners();
    });
    
    // Escuchar cambios en consumo global total
    _firebaseService.totalGlobalConsumptionStream().listen((consumption) {
      _totalGlobalConsumption = consumption;
      notifyListeners();
    });
  }

  // ========== CRUD ACTIVIDADES ==========

  /// Agregar nueva actividad
  Future<bool> addActivity({
    required ActivityType activityType,
    required double quantity,
  }) async {
    try {
      _error = null;
      
      await _firebaseService.addActivity(
        activityTypeId: activityType.id,
        activityName: activityType.name,
        quantity: quantity,
        litersPerUnit: activityType.litersPerUnit,
        category: activityType.category,
        icon: activityType.icon,
        unit: activityType.unit,
      );
      
      // Refrescar datos
      await initialize();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualizar actividad existente
  Future<bool> updateActivity({
    required String recordId,
    required String activityId,
    required double quantity,
    required double litersPerUnit,
  }) async {
    try {
      _error = null;
      
      await _firebaseService.updateActivity(
        recordId: recordId,
        activityId: activityId,
        quantity: quantity,
        litersPerUnit: litersPerUnit,
      );
      
      // Refrescar datos
      await initialize();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Eliminar actividad
  Future<bool> deleteActivity(String recordId, String activityId) async {
    try {
      _error = null;
      
      await _firebaseService.deleteActivity(recordId, activityId);
      
      // Refrescar datos
      await initialize();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========== HISTORIAL Y ESTADÍSTICAS ==========

  /// Obtener historial de días anteriores
  Future<List<DailyRecord>> getDailyHistory({int days = 30}) async {
    try {
      return await _firebaseService.getDailyRecords(days: days);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Obtener actividades de un día específico
  Future<List<Activity>> getActivitiesForRecord(String recordId) async {
    try {
      return await _firebaseService.getActivitiesForDay(recordId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Eliminar registro diario completo
  Future<bool> deleteDailyRecord(String recordId) async {
    try {
      _error = null;
      
      await _firebaseService.deleteDailyRecord(recordId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtener estadísticas
  Future<Map<String, dynamic>> getStatistics({int days = 7}) async {
    try {
      return await _firebaseService.getStatistics(days: days);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // ========== UTILIDADES ==========

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Buscar tipo de actividad por ID
  ActivityType? getActivityTypeById(String id) {
    try {
      return _activityTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}
