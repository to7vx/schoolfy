// Quick setup script to add basic data to empty collections
// Run this in the browser console while logged into your admin dashboard

async function setupBasicData() {
  console.log('Setting up basic data for empty collections...');
  
  const db = firebase.firestore();
  const auth = firebase.auth();
  const user = auth.currentUser;
  
  if (!user) {
    console.error('Please log in first');
    return;
  }
  
  try {
    // 1. Add admin document
    await db.collection('admins').doc(user.uid).set({
      email: user.email,
      status: 'active',
      role: 'super_admin',
      name: 'Admin User',
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      permissions: ['all']
    });
    console.log('✓ Admin document created');
    
    // 2. Add user document
    await db.collection('users').doc(user.uid).set({
      email: user.email,
      role: 'admin',
      name: 'Admin User',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    console.log('✓ User document created');
    
    // 3. Add sample grades
    const grades = ['KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'];
    for (let grade of grades) {
      await db.collection('grades').add({
        name: grade,
        displayName: grade,
        order: grades.indexOf(grade),
        active: true,
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });
    }
    console.log('✓ Sample grades created');
    
    // 4. Add school document
    await db.collection('schools').add({
      name: 'Sample School',
      address: '123 School Street',
      phone: '+1234567890',
      email: 'info@sampleschool.edu',
      active: true,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    console.log('✓ School document created');
    
    // 5. Add sample settings
    await db.collection('settings').doc('general').set({
      schoolName: 'Sample School',
      academicYear: '2024-2025',
      timezone: 'America/New_York',
      pickupStartTime: '14:00',
      pickupEndTime: '16:00',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    console.log('✓ Settings document created');
    
    // 6. Add sample students
    for (let i = 1; i <= 5; i++) {
      await db.collection('students').add({
        name: `Student ${i}`,
        grade: grades[Math.floor(Math.random() * grades.length)],
        studentId: `STU${String(i).padStart(3, '0')}`,
        status: 'active',
        guardianPhone: `+123456789${i}`,
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });
    }
    console.log('✓ Sample students created');
    
    console.log('🎉 Basic data setup complete! Try refreshing your dashboard.');
    
  } catch (error) {
    console.error('Error setting up data:', error);
  }
}

// Auto-run the setup
setupBasicData();
