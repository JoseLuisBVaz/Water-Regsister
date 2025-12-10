const admin = require('firebase-admin');
const serviceAccount = require('./agua-41cd1-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupOldGlobalDoc() {
  try {
    console.log('🧹 Eliminando documento viejo de global_stats...\n');
    
    // Eliminar el documento water_consumption
    await db.collection('global_stats').doc('water_consumption').delete();
    
    console.log('✅ Documento "water_consumption" eliminado correctamente!\n');
    
    // Verificar documentos restantes
    console.log('📊 Verificando documentos restantes...\n');
    const snapshot = await db.collection('global_stats').get();
    
    console.log(`Total de documentos: ${snapshot.docs.length}\n`);
    
    let totalSum = 0;
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`📄 ${doc.id}: ${data.totalLiters || 0} L`);
      totalSum += (data.totalLiters || 0);
    });
    
    console.log(`\n💧 TOTAL CORRECTO: ${totalSum} L\n`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

cleanupOldGlobalDoc();
