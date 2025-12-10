# Script para poblar Firebase con los tipos de actividades
# Copia estos datos manualmente en Firestore Console o usa Firebase Admin SDK

ACTIVIDADES_INICIALES = [
    {
        "name": "Ducha",
        "litersPerUnit": 8.0,
        "category": "Higiene",
        "unit": "minutos",
        "icon": "🚿"
    },
    {
        "name": "Usar WC",
        "litersPerUnit": 6.0,
        "category": "Higiene",
        "unit": "veces",
        "icon": "🚽"
    },
    {
        "name": "Lavar platos a mano",
        "litersPerUnit": 20.0,
        "category": "Limpieza",
        "unit": "sesiones",
        "icon": "🍽️"
    },
    {
        "name": "Lavavajillas",
        "litersPerUnit": 15.0,
        "category": "Limpieza",
        "unit": "cargas",
        "icon": "🔧"
    },
    {
        "name": "Lavadora",
        "litersPerUnit": 70.0,
        "category": "Limpieza",
        "unit": "cargas",
        "icon": "👕"
    },
    {
        "name": "Regar plantas",
        "litersPerUnit": 10.0,
        "category": "Jardín",
        "unit": "sesiones",
        "icon": "🌱"
    },
    {
        "name": "Cepillar dientes",
        "litersPerUnit": 5.0,
        "category": "Higiene",
        "unit": "minutos",
        "icon": "🦷"
    },
    {
        "name": "Lavar manos",
        "litersPerUnit": 2.0,
        "category": "Higiene",
        "unit": "veces",
        "icon": "🧼"
    },
    {
        "name": "Cocinar",
        "litersPerUnit": 15.0,
        "category": "Cocina",
        "unit": "sesiones",
        "icon": "🍳"
    },
    {
        "name": "Lavar auto",
        "litersPerUnit": 150.0,
        "category": "Otros",
        "unit": "lavados",
        "icon": "🚗"
    },
    {
        "name": "Limpiar piso",
        "litersPerUnit": 12.0,
        "category": "Limpieza",
        "unit": "sesiones",
        "icon": "🧹"
    },
    {
        "name": "Llenar piscina",
        "litersPerUnit": 500.0,
        "category": "Otros",
        "unit": "llenadas",
        "icon": "🏊"
    }
]

# Estructura de Firestore:
# 
# activity_types/ (colección)
#   ├── {activityId1}
#   │   ├── name: "Ducha"
#   │   ├── litersPerUnit: 8.0
#   │   ├── category: "Higiene"
#   │   ├── unit: "minutos"
#   │   └── icon: "🚿"
#   └── {activityId2}
#       └── ...
#
# users/ (colección)
#   └── {userId}
#       └── daily_records/ (subcolección)
#           └── {recordId}
#               ├── date: Timestamp
#               ├── dateKey: "2025-12-09"
#               ├── totalLiters: 150.5
#               ├── activitiesCount: 8
#               └── activities/ (subcolección)
#                   └── {activityId}
#                       ├── activityTypeId: "abc123"
#                       ├── activityName: "Ducha"
#                       ├── quantity: 10
#                       ├── litersUsed: 80.0
#                       ├── category: "Higiene"
#                       ├── icon: "🚿"
#                       └── timestamp: Timestamp

# PASOS PARA CONFIGURAR FIREBASE:
#
# 1. Ir a https://console.firebase.google.com/
# 2. Crear un nuevo proyecto (o usar uno existente)
# 3. Agregar una app (Android/iOS/Web)
# 4. Habilitar Firestore Database (modo test por ahora)
# 5. Crear la colección "activity_types"
# 6. Agregar documentos manualmente con los datos de arriba
#    O usar la consola de Firebase para importar estos datos
#
# Para Android:
#   - Descargar google-services.json
#   - Colocar en: android/app/google-services.json
#   - Agregar plugin en android/build.gradle.kts
#
# Para iOS:
#   - Descargar GoogleService-Info.plist
#   - Colocar en: ios/Runner/GoogleService-Info.plist
