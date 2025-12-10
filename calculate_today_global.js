const admin = require('firebase-admin');
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function calculateTodayGlobalConsumption() {
  try {
    console.log('🔍 Calculando consumo global del día actual...\n');
    
    // Obtener la fecha de hoy
    const today = new Date();
    const dateKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    
    console.log(`📅 Fecha actual: ${dateKey}\n`);
    
    let totalLiters = 0;
    let totalActivities = 0;
    let usersFound = 0;
    
    // Buscar todos los usuarios
    const usersSnapshot = await db.collection('users').listDocuments();
    
    for (const userRef of usersSnapshot) {
      usersFound++;
      const userId = userRef.id;
      console.log(`👤 Usuario: ${userId}`);
      
      // Buscar el registro del día actual de este usuario
      const todayRecordSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('daily_records')
        .where('dateKey', '==', dateKey)
        .get();
      
      if (todayRecordSnapshot.empty) {
        console.log(`  ℹ️  No tiene registros de hoy\n`);
        continue;
      }
      
      for (const recordDoc of todayRecordSnapshot.docs) {
        console.log(`  📋 Registro del día: ${recordDoc.id}`);
        
        // Obtener todas las actividades de hoy
        const activitiesSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('daily_records')
          .doc(recordDoc.id)
          .collection('activities')
          .get();
        
        console.log(`    🏃 ${activitiesSnapshot.docs.length} actividades`);
        
        activitiesSnapshot.docs.forEach(activityDoc => {
          const data = activityDoc.data();
          const liters = data.litersUsed || 0;
          console.log(`      💧 ${data.activityName || 'Sin nombre'}: ${liters} L`);
          totalLiters += liters;
          totalActivities++;
        });
      }
      console.log();
    }
    
    console.log('\n═══════════════════════════════════════');
    console.log('📊 RESUMEN DEL DÍA ACTUAL');
    console.log('═══════════════════════════════════════');
    console.log(`👥 Usuarios encontrados: ${usersFound}`);
    console.log(`🏃 Actividades del día: ${totalActivities}`);
    console.log(`💧 CONSUMO GLOBAL DE HOY: ${totalLiters} L`);
    console.log('═══════════════════════════════════════\n');
    
    // Actualizar en Firestore
    console.log('💾 Actualizando consumo global en Firestore...');
    
    await db.collection('global_stats').doc(dateKey).set({
      totalLiters: totalLiters,
      date: admin.firestore.Timestamp.fromDate(new Date(today.getFullYear(), today.getMonth(), today.getDate())),
      dateKey: dateKey,
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      activitiesCount: totalActivities,
      usersCount: usersFound
    });
    
    console.log('✅ Consumo global del día actualizado correctamente!\n');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

calculateTodayGlobalConsumption();
