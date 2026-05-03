const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Initialize with default credentials (uses GOOGLE_APPLICATION_CREDENTIALS or ADC)
const app = initializeApp({ projectId: 'luxelane-4e7ae' });
const db = getFirestore(app);
const auth = getAuth(app);

async function promoteAdmin() {
  const email = 'admin@luxelane.com';
  
  try {
    console.log(`Looking up user: ${email}`);
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;
    console.log(`Found user UID: ${uid}`);
    
    const docRef = db.collection('users').doc(uid);
    const doc = await docRef.get();
    
    if (!doc.exists) {
      console.error('User document NOT found in Firestore users collection!');
      console.log('The user exists in Firebase Auth but has no Firestore profile.');
      process.exit(1);
    }
    
    const data = doc.data();
    console.log(`Current role: ${data.role}`);
    
    await docRef.update({ role: 'admin', isVerified: true });
    console.log('✅ Successfully updated role to "admin" and verified the account!');
    
    const updated = await docRef.get();
    console.log(`New role: ${updated.data().role}`);
    
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.error('User not found in Firebase Auth. Have you registered with this email?');
    } else {
      console.error('Error:', err.message);
    }
    process.exit(1);
  }
}

promoteAdmin().then(() => process.exit(0));
