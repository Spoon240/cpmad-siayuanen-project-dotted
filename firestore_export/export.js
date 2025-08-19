const firestoreService = require('firestore-export-import');
const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccount = './fs-apikey.json';
const backupFile = './fs-backup.json';

admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccount))
});
const db = admin.firestore();

async function backupCollections() {
    try {
        console.log('Exporting Firestore collections...');
        const collections = ['barcodes', 'foods_public', 'users']; // only these
        const data = {};

        for (const col of collections) {
            console.log(`Backing up collection: ${col}`);
            data[col] = await firestoreService.backup(db, col);
        }

        fs.writeFileSync(backupFile, JSON.stringify(data, null, 2));
        console.log(`✅ Backup saved to ${backupFile}`);
    } catch (err) {
        console.error('❌ Error exporting Firestore:', err);
    }
}

backupCollections();