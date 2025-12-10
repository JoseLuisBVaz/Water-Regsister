# Proyecto Final
# Elaborado por: Berlanga Vazquez Jose Luis & Flores Rosales Ariel Naim  - 9B ITI
# Programacion Movil
# Mtra. Faride Hernández Pérez


# AWA - Aplicación de Ahorro de Agua 💧

Aplicación móvil en Flutter con enfoque social/ecológico, destinada a ayudar a las personas a reducir su consumo diario de agua mediante seguimiento, registro y visualización de hábitos.

## 🌟 Características

### Funcionalidades Principales

#### 📱 Pantalla Principal (Home)
- ✅ Muestra el consumo total del día en un card destacado
- ✅ Lista de actividades registradas usando `ListView` + `Card` + `CircleAvatar`
- ✅ FAB (FloatingActionButton) para agregar nuevas actividades
- ✅ Pull-to-refresh para actualizar datos

#### ➕ Agregar Actividad
- ✅ Formulario con `DropdownButton` para seleccionar actividad
- ✅ Campo numérico para ingresar cantidad con validación
- ✅ Cálculo automático de litros en tiempo real
- ✅ Botón guardar con `AlertDialog` de confirmación
- ✅ Animación Hero al guardar y regresar

#### 📜 Historial
- ✅ `ListView` con consumo diario de días anteriores (últimos 30 días)
- ✅ Cards mostrando fecha y litros totales
- ✅ Tap en card para ver detalle de actividades del día
- ✅ Opción de eliminar registros con confirmación

#### 📊 Estadísticas
- ✅ Consumo semanal y mensual basado en registros
- ✅ Cards informativos con:
  - Total del período
  - Promedio diario
  - Día con mayor consumo
  - Día con menor consumo
- ✅ Selector de período (7, 30, 90 días)
- ✅ Consejos ecológicos para ahorrar agua

## 🔥 Firebase - Estructura de Datos

### Operaciones CRUD Implementadas

✅ **Consulta (READ)**: Lectura de actividades y totales diarios  
✅ **Inserción (CREATE)**: Agregar nuevas actividades  
✅ **Actualización (UPDATE)**: Editar actividades existentes  
✅ **Eliminación (DELETE)**: Borrar actividades o días completos

### Estructura en Firestore

```
activity_types/ (colección - catálogo de actividades)
  ├── {activityTypeId}
  │   ├── name: "Ducha"
  │   ├── litersPerUnit: 8.0
  │   ├── category: "Higiene"
  │   ├── unit: "minutos"
  │   └── icon: "🚿"

users/ (colección)
  └── {userId}
      └── daily_records/ (subcolección)
          └── {recordId}
              ├── date: Timestamp
              ├── dateKey: "2025-12-09"
              ├── totalLiters: 150.5
              ├── activitiesCount: 8
              └── activities/ (subcolección)
                  └── {activityId}
                      ├── activityTypeId: "abc123"
                      ├── activityName: "Ducha"
                      ├── quantity: 10
                      ├── litersUsed: 80.0
                      ├── category: "Higiene"
                      ├── icon: "🚿"
                      └── timestamp: Timestamp
```

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  
  # Gestión de estado
  provider: ^6.1.2
  
  # Gráficos (preparado para futuras versiones)
  fl_chart: ^0.69.0
  
  # Utilidades
  intl: ^0.19.0
  shared_preferences: ^2.3.2
```

## 🚀 Configuración de Firebase

### Paso 1: Crear Proyecto en Firebase

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear un nuevo proyecto o usar uno existente
3. Nombre sugerido: `awa-water-tracker`

### Paso 2: Habilitar Firestore

1. En la consola de Firebase, ir a **Firestore Database**
2. Crear base de datos en modo **test** (o modo producción con reglas personalizadas)
3. Ubicación: elegir la más cercana (por ejemplo, `us-central1`)

### Paso 3: Poblar Datos Iniciales

Crear la colección `activity_types` con estos documentos (ver `firebase_seed_data.py`):

| ID | name | litersPerUnit | category | unit | icon |
|----|------|---------------|----------|------|------|
| Auto-generado | Ducha | 8.0 | Higiene | minutos | 🚿 |
| Auto-generado | Usar WC | 6.0 | Higiene | veces | 🚽 |
| Auto-generado | Lavar platos a mano | 20.0 | Limpieza | sesiones | 🍽️ |
| Auto-generado | Lavavajillas | 15.0 | Limpieza | cargas | 🔧 |
| Auto-generado | Lavadora | 70.0 | Limpieza | cargas | 👕 |
| Auto-generado | Regar plantas | 10.0 | Jardín | sesiones | 🌱 |
| Auto-generado | Cepillar dientes | 5.0 | Higiene | minutos | 🦷 |
| Auto-generado | Lavar manos | 2.0 | Higiene | veces | 🧼 |
| Auto-generado | Cocinar | 15.0 | Cocina | sesiones | 🍳 |
| Auto-generado | Lavar auto | 150.0 | Otros | lavados | 🚗 |

### Paso 4: Configurar Android

1. En Firebase Console, agregar app Android
2. Nombre del paquete: `com.example.awa` (o el que uses)
3. Descargar `google-services.json`
4. Colocar en: `android/app/google-services.json`

5. Editar `android/build.gradle.kts` (nivel proyecto):
```kotlin
buildscript {
    dependencies {
        // Agregar:
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

6. Editar `android/app/build.gradle.kts`:
```kotlin
plugins {
    // ... otros plugins
    id("com.google.gms.google-services")
}
```

### Paso 5: Configurar iOS (opcional)

1. En Firebase Console, agregar app iOS
2. Bundle ID: `com.example.awa` (o el que uses)
3. Descargar `GoogleService-Info.plist`
4. Colocar en: `ios/Runner/GoogleService-Info.plist`
5. Abrir `ios/Runner.xcworkspace` en Xcode
6. Arrastrar el archivo `.plist` al proyecto

### Paso 6: Inicializar Firebase en la App

En `lib/main.dart`, descomentar estas líneas una vez configurado:

```dart
// TODO: Inicializar Firebase
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Y agregar Firebase CLI tools:
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase automáticamente
flutterfire configure
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada
├── models/
│   ├── activity_type.dart              # Modelo de tipo de actividad
│   ├── activity.dart                   # Modelo de actividad registrada
│   └── daily_record.dart               # Modelo de registro diario
├── services/
│   └── firebase_service.dart           # Servicio CRUD de Firebase
├── providers/
│   └── water_consumption_provider.dart # Gestión de estado con Provider
├── screens/
│   ├── home_screen.dart                # Pantalla principal
│   ├── register_activity_screen.dart   # Registrar actividad
│   ├── history_screen.dart             # Historial de días
│   └── statistics_screen.dart          # Estadísticas y gráficos
└── widgets/
    └── (widgets reutilizables futuros)
```

## 🎨 Tema y Colores

- **Color primario**: Azul (#0077BE) - Representa el agua
- **Color secundario**: Verde (#4CAF50) - Representa ecología
- **Material 3**: Activado
- **Tipografía**: Roboto (por defecto)

## 🏃 Ejecutar la App

### Requisitos
- Flutter SDK 3.5.3 o superior
- Android Studio / Xcode (según plataforma)
- Conexión a internet (para Firebase)

### Comandos

```bash
# Obtener dependencias
flutter pub get

# Verificar errores
flutter analyze

# Ejecutar en emulador/dispositivo
flutter run

# Build para Android
flutter build apk

# Build para iOS
flutter build ios
```

## ⚠️ Notas Importantes

### Para Modo Test de Firestore
Si usas modo test, Firebase permite acceso sin autenticación por tiempo limitado. Cambia estas reglas cuando pases a producción:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Modo TEST (cambiar en producción)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Usuario Actual
Por ahora la app usa `default_user` como ID de usuario. Para implementar autenticación real:

1. Habilitar Firebase Authentication
2. Implementar login (anónimo, email, Google, etc.)
3. Reemplazar `userId` en `FirebaseService`

## 📝 TO-DO / Mejoras Futuras

- [ ] Autenticación de usuarios (Firebase Auth)
- [ ] Gráficos visuales con `fl_chart`
- [ ] Modo oscuro
- [ ] Notificaciones recordatorias
- [ ] Metas de reducción de consumo
- [ ] Compartir estadísticas
- [ ] Exportar datos a CSV
- [ ] Soporte multiidioma
- [ ] Comparación con otros usuarios (rankings)
- [ ] Logros y badges

## 👥 Créditos

Desarrollado con ❤️ y Flutter

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.
