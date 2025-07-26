// Run this in your browser console while logged into the admin dashboard
// This will create your admin account in the admins collection

async function setupAdminAccount() {
  console.log('🔧 Setting up admin account...');
  
  try {
    const auth = firebase.auth();
    const db = firebase.firestore();
    
    // Check if user is logged in
    const currentUser = auth.currentUser;
    if (!currentUser) {
      console.log('❌ No user logged in. Please log in first.');
      return;
    }
    
    console.log('✅ User logged in:', currentUser.email);
    
    // Create admin document
    const adminData = {
      email: currentUser.email,
      status: 'active',
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: firebase.firestore.FieldValue.serverTimestamp(),
      role: 'admin'
    };
    
    await db.collection('admins').doc(currentUser.uid).set(adminData);
    console.log('✅ Admin document created successfully!');
    
    // Also create user document if needed
    const userDoc = await db.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) {
      await db.collection('users').doc(currentUser.uid).set({
        email: currentUser.email,
        role: 'admin',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✅ User document created successfully!');
    } else {
      console.log('✅ User document already exists');
    }
    
    console.log('🎉 Admin setup complete! Refresh the page to see changes.');
    
  } catch (error) {
    console.error('❌ Error setting up admin account:', error);
  }
}

// Instructions
console.log('📝 To setup your admin account:');
console.log('1. Make sure you are logged into the admin dashboard');
console.log('2. Run: setupAdminAccount()');
console.log('3. Refresh the page after setup');

// Auto-run the setup
setupAdminAccount();
