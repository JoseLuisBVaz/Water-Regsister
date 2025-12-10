const admin = require('firebase-admin');
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function calculateGlobalConsumption() {
  try {
    console.log('🔍 Calculando consumo global...');
    console.log('📊 Buscando en todas las colecciones...\n');
    
    let totalLiters = 0;
    let totalActivities = 0;
    let usersFound = 0;
    
    // Método 1: Buscar directamente en la colección users
    console.log('Método 1: Buscando en /users...');
    const usersSnapshot = await db.collection('users').listDocuments();
    
    for (const userRef of usersSnapshot) {
      usersFound++;
      const userId = userRef.id;
      console.log(`\n👤 Usuario encontrado: ${userId}`);
      
      // Obtener todos los daily_records de este usuario
      const recordsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('daily_records')
        .get();
      
      console.log(`  📅 ${recordsSnapshot.docs.length} registros diarios`);
      
      for (const recordDoc of recordsSnapshot.docs) {
        const recordData = recordDoc.data();
        console.log(`    📋 Registro: ${recordDoc.id} - ${recordData.totalLiters || 0} L`);
        
        // Obtener todas las actividades de este registro
        const activitiesSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordDoc.id)
          .collection('activities')
          .get();
        
        console.log(`      🏃 ${activitiesSnapshot.docs.length} actividades`);
        
        activitiesSnapshot.docs.forEach(activityDoc => {
          const data = activityDoc.data();
          const liters = data.litersUsed || 0;
          console.log(`        💧 Actividad: ${data.activityName || 'Sin nombre'} - ${liters} L`);
          totalLiters += liters;
          totalActivities++;
        });
      }
    }
    
    console.log(`\n📊 Resumen:`);
    console.log(`   👥 Usuarios encontrados: ${usersFound}`);
    console.log(`   💧 Total calculado: ${totalLiters} litros`);
    console.log(`   📋 Total de actividades: ${totalActivities}`);
    
    if (totalLiters === 0 && usersFound === 0) {
      console.log('\n⚠️  No se encontraron usuarios. Esto puede ser normal si nadie ha iniciado sesión aún.');
      console.log('   El consumo global se actualizará automáticamente cuando alguien agregue actividades.');
    }
    
    // Actualizar el documento global
    await db.collection('global_stats').doc('water_consumption').set({
      totalLiters: totalLiters,
      totalActivities: totalActivities,
      usersCount: usersFound,
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      lastCalculation: new Date().toISOString()
    });
    
    console.log('\n✅ Consumo global actualizado en Firestore');
    console.log(`🌍 Nuevo consumo global: ${totalLiters} L`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

calculateGlobalConsumption();
