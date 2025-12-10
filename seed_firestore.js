const admin = require('firebase-admin');

// Inicializar Firebase Admin con las credenciales del proyecto
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Datos a insertar (ya hiciste el primero, así que empezamos del segundo)
const actividades = [
  {
    name: "Usar WC",
    litersPerUnit: 6.0,
    category: "Higiene",
    unit: "veces",
    icon: "🚽"
  },
  {
    name: "Lavar platos a mano",
    litersPerUnit: 20.0,
    category: "Limpieza",
    unit: "sesiones",
    icon: "🍽️"
  },
  {
    name: "Lavavajillas",
    litersPerUnit: 15.0,
    category: "Limpieza",
    unit: "cargas",
    icon: "🔧"
  },
  {
    name: "Lavadora",
    litersPerUnit: 70.0,
    category: "Limpieza",
    unit: "cargas",
    icon: "👕"
  },
  {
    name: "Regar plantas",
    litersPerUnit: 10.0,
    category: "Jardín",
    unit: "sesiones",
    icon: "🌱"
  },
  {
    name: "Cepillar dientes",
    litersPerUnit: 5.0,
    category: "Higiene",
    unit: "minutos",
    icon: "🦷"
  },
  {
    name: "Lavar manos",
    litersPerUnit: 2.0,
    category: "Higiene",
    unit: "veces",
    icon: "🧼"
  },
  {
    name: "Cocinar",
    litersPerUnit: 15.0,
    category: "Cocina",
    unit: "sesiones",
    icon: "🍳"
  },
  {
    name: "Lavar auto",
    litersPerUnit: 150.0,
    category: "Otros",
    unit: "lavados",
    icon: "🚗"
  }
];

async function poblarDatos() {
  console.log('🔥 Poblando Firestore con actividades...\n');
  
  const batch = db.batch();
  const collectionRef = db.collection('activity_types');

  for (const actividad of actividades) {
    const docRef = collectionRef.doc(); // Auto-ID
    batch.set(docRef, actividad);
    console.log(`✅ ${actividad.name} - ${actividad.litersPerUnit} L/${actividad.unit}`);
  }

  await batch.commit();
  console.log('\n✅ ¡Todos los datos fueron agregados exitosamente!');
  process.exit(0);
}

poblarDatos().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
