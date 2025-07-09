// Script to add sample data to Firestore for testing phone linking
// You can run this in Firebase Console or use Firebase Admin SDK

// First, let's create some students with guardian phone numbers
const sampleStudents = [
  {
    name: 'Sara Al-Zanbaqi',
    grade: '2A',
    schoolId: 'SCH_001',
    guardianPhone: '+966512345678', // Test phone number
    primaryGuardianId: null, // Will be set when guardian logs in
    authorizedGuardianIds: [],
    status: 'pending',
    createdAt: new Date(),
  },
  {
    name: 'Omar Al-Zanbaqi',
    grade: '4B',
    schoolId: 'SCH_001',
    guardianPhone: '+966512345678', // Same guardian as Sara
    primaryGuardianId: null,
    authorizedGuardianIds: [],
    status: 'pending',
    createdAt: new Date(),
  },
  {
    name: 'Fatima Al-Rashid',
    grade: '3C',
    schoolId: 'SCH_001',
    guardianPhone: '+966587654321', // Different guardian
    primaryGuardianId: null,
    authorizedGuardianIds: [],
    status: 'pending',
    createdAt: new Date(),
  },
];

// Sample school data
const sampleSchool = {
  name: 'Al-Noor Elementary School',
  address: 'Riyadh, Saudi Arabia',
  phone: '+966114567890',
  createdAt: new Date(),
};

// To add this data to Firestore:
// 1. Go to Firebase Console > Firestore Database
// 2. Create a 'students' collection
// 3. Add each student as a document with auto-generated ID
// 4. Create a 'schools' collection
// 5. Add the school with ID 'SCH_001'

// For testing the app:
// 1. Use Firebase Auth phone login with +966512345678
//    - Should automatically link to Sara and Omar
// 2. Use Firebase Auth phone login with +966587654321
//    - Should automatically link to Fatima
// 3. Use Firebase Auth phone login with +966999999999
//    - Should show "No linked students yet"

console.log('Sample data structure ready for Firebase Console');
console.log('Students:', sampleStudents);
console.log('School:', sampleSchool);
