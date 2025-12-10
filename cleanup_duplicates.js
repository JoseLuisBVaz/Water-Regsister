const admin = require('firebase-admin');
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupDuplicateRecords() {
  try {
    console.log('🔍 Buscando registros duplicados...');
    
    // Obtener todos los usuarios
    const usersSnapshot = await db.collection('users').get();
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`\n👤 Usuario: ${userId}`);
      
      // Obtener todos los daily_records de este usuario
      const recordsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('daily_records')
        .get();
      
      // Agrupar por dateKey
      const recordsByDate = {};
      recordsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const dateKey = data.dateKey;
        
        if (!recordsByDate[dateKey]) {
          recordsByDate[dateKey] = [];
        }
        
        recordsByDate[dateKey].push({
          id: doc.id,
          data: data
        });
      });
      
      // Eliminar duplicados
      for (const [dateKey, records] of Object.entries(recordsByDate)) {
        if (records.length > 1) {
          console.log(`  📅 Fecha ${dateKey}: ${records.length} registros duplicados`);
          
          // Mantener el primero, eliminar el resto
          const toKeep = records[0];
          const toDelete = records.slice(1);
          
          console.log(`    ✅ Manteniendo: ${toKeep.id}`);
          
          for (const record of toDelete) {
            console.log(`    🗑️  Eliminando: ${record.id}`);
            
            // Primero eliminar todas las actividades del registro duplicado
            const activitiesSnapshot = await db
              .collection('users')
              .doc(userId)
              .collection('daily_records')
              .doc(record.id)
              .collection('activities')
              .get();
            
            // Si el registro a eliminar tiene actividades, moverlas al registro que vamos a mantener
            if (!activitiesSnapshot.empty) {
              console.log(`      📦 Moviendo ${activitiesSnapshot.docs.length} actividades...`);
              
              for (const activityDoc of activitiesSnapshot.docs) {
                const activityData = activityDoc.data();
                
                // Agregar la actividad al registro que vamos a mantener
                await db
                  .collection('users')
                  .doc(userId)
                  .collection('daily_records')
                  .doc(toKeep.id)
                  .collection('activities')
                  .add(activityData);
                
                // Eliminar la actividad del registro duplicado
                await activityDoc.ref.delete();
              }
            }
            
            // Ahora eliminar el registro duplicado
            await db
              .collection('users')
              .doc(userId)
              .collection('daily_records')
              .doc(record.id)
              .delete();
          }
          
          // Recalcular totales del registro que mantuvimos
          const activitiesSnapshot = await db
            .collection('users')
            .doc(userId)
            .collection('daily_records')
            .doc(toKeep.id)
            .collection('activities')
            .get();
          
          let totalLiters = 0;
          activitiesSnapshot.docs.forEach(doc => {
            const data = doc.data();
            totalLiters += data.litersUsed || 0;
          });
          
          await db
            .collection('users')
            .doc(userId)
            .collection('daily_records')
            .doc(toKeep.id)
            .update({
              totalLiters: totalLiters,
              activitiesCount: activitiesSnapshot.docs.length
            });
          
          console.log(`    💧 Totales actualizados: ${totalLiters} L, ${activitiesSnapshot.docs.length} actividades`);
        }
      }
    }
    
    console.log('\n✅ Limpieza completada');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

cleanupDuplicateRecords();
