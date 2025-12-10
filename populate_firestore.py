import firebase_admin
from firebase_admin import credentials, firestore

# Inicializar Firebase Admin
# NOTA: Debes descargar la clave privada desde Firebase Console
# Settings > Service accounts > Generate new private key
# Y guardarla como 'serviceAccountKey.json' en esta carpeta

try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
except:
    print("⚠️ No se encontró serviceAccountKey.json")
    print("Debes descargar la clave desde Firebase Console")
    print("Settings > Service accounts > Generate new private key")
    exit(1)

db = firestore.client()

# Tipos de actividades para poblar
ACTIVIDADES = [
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
    }
]

print("🔥 Poblando Firestore con tipos de actividades...")
print("=" * 50)

collection_ref = db.collection('activity_types')

for actividad in ACTIVIDADES:
    doc_ref = collection_ref.add(actividad)
    print(f"✅ {actividad['name']} - {actividad['litersPerUnit']} L/{actividad['unit']}")

print("=" * 50)
print("✅ ¡Datos poblados exitosamente!")
print("\nAhora puedes ejecutar tu app Flutter:")
print("  flutter run")
