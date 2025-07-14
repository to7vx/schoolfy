// Script to create admin user in Firestore
// Run this in Firebase Console's JavaScript console or use it as reference

// Admin user data for admin@schoolfy.com
const adminData = {
  email: "admin@schoolfy.com",
  name: "Admin User",
  role: "admin", 
  status: "active",
  permissions: {
    manageStudents: true,
    manageGuardians: true,
    viewPickupHistory: true,
    exportData: true,
    manageAdmins: true
  },
  createdAt: new Date(),
  lastLoginAt: null
};

// To add this admin to your Firestore database:
// 1. Go to Firebase Console > Firestore Database
// 2. Create a new collection called "admins"
// 3. Add a document with the admin's UID or email as the document ID
// 4. Copy the adminData object above as the document fields

console.log("Admin data to add to Firestore:");
console.log(JSON.stringify(adminData, null, 2));

// Alternative: If you know the admin's Firebase Auth UID, use that as the document ID
// If you don't know the UID, you can use the email as a document identifier
// Document ID suggestion: Use the Firebase Auth UID of admin@schoolfy.com

/* Instructions:
1. Sign in to Firebase Console
2. Go to your project
3. Navigate to Firestore Database
4. Create collection "admins" if it doesn't exist
5. Add new document with ID = Firebase Auth UID of admin@schoolfy.com
6. Add the fields from adminData above
7. Save the document

The admin will then be able to access the dashboard.
*/
