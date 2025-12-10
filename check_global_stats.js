const admin = require('firebase-admin');
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkGlobalStats() {
  try {
    console.log('🔍 Verificando documentos en global_stats...\n');
    
    const snapshot = await db.collection('global_stats').get();
    
    console.log(`📊 Total de documentos: ${snapshot.docs.length}\n`);
    
    let totalSum = 0;
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`📄 Documento ID: ${doc.id}`);
      console.log(`   - totalLiters: ${data.totalLiters || 0} L`);
      console.log(`   - dateKey: ${data.dateKey || 'N/A'}`);
      console.log(`   - lastUpdate: ${data.lastUpdate ? data.lastUpdate.toDate() : 'N/A'}`);
      console.log();
      
      totalSum += (data.totalLiters || 0);
    });
    
    console.log('═══════════════════════════════════════');
    console.log(`💧 SUMA TOTAL: ${totalSum} L`);
    console.log('═══════════════════════════════════════\n');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

checkGlobalStats();
