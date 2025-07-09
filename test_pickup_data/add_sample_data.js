const admin = require('firebase-admin');

// You'll need to replace this with your actual Firebase service account key
// For now, this is just a template - you would need to add your actual Firebase config
const serviceAccount = {
  // Add your Firebase service account credentials here
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://your-project-id-default-rtdb.firebaseio.com"
});

const database = admin.database();

async function addSamplePickupData() {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
  
  const sampleData = {
    [`pickup_${Date.now()}_1`]: {
      studentId: "STU001",
      studentName: "أحمد محمد",
      grade: "الصف الأول",
      time: new Date().toISOString(),
      guardianName: "محمد أحمد",
      guardianPhone: "+966501234567"
    },
    [`pickup_${Date.now()}_2`]: {
      studentId: "STU002", 
      studentName: "فاطمة علي",
      grade: "الصف الثاني",
      time: new Date().toISOString(),
      guardianName: "علي حسن",
      guardianPhone: "+966501234568"
    },
    [`pickup_${Date.now()}_3`]: {
      studentId: "STU003",
      studentName: "عبدالله سعد", 
      grade: "الصف الثالث",
      time: new Date().toISOString(),
      guardianName: "سعد عبدالله",
      guardianPhone: "+966501234569"
    }
  };

  try {
    await database.ref(`pickupQueue/${today}`).update(sampleData);
    console.log('Sample pickup data added successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error adding sample data:', error);
    process.exit(1);
  }
}

addSamplePickupData();
