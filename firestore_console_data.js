// 📋 COPY AND PASTE THIS INTO FIREBASE CONSOLE
// Go to: https://console.firebase.google.com/project/schoolfy-706ff/firestore/data

// 1. Create 'students' collection
// Click "Start collection" -> Enter collection ID: "students"

// 2. Add Student 1:
// Document ID: (auto-generated)
// Fields:
{
  "name":"Sara Al-Zanbaqi",
  "grade": 2A",
  "schoolId": "SCH_001",
  "guardianPhone": "+966512345678",
  "primaryGuardianId": null,
  "authorizedGuardianIds": [],
  "status": "pending",
  "createdAt": "2025-07-09T00:00:00.000Z"
}

// 3. Add Student 2:
// Document ID: (auto-generated)
// Fields:
{
  "name": "Omar Al-Zanbaqi",
  "grade": "4B",
  "schoolId": "SCH_001",
  "guardianPhone": "+966512345678",
  "primaryGuardianId": null,
  "authorizedGuardianIds": [],
  "status": "pending",
  "createdAt": "2025-07-09T00:00:00.000Z"
}

// 4. Add Student 3:
// Document ID: (auto-generated)
// Fields:
{
  "name": "Fatima Al-Rashid",
  "grade": "3C",
  "schoolId": "SCH_001",
  "guardianPhone": "+966587654321",
  "primaryGuardianId": null,
  "authorizedGuardianIds": [],
  "status": "pending",
  "createdAt": "2025-07-09T00:00:00.000Z"
}

// 5. Add Student 4:
// Document ID: (auto-generated)
// Fields:
{
  "name": "Ahmed Al-Mansouri",
  "grade": "1A",
  "schoolId": "SCH_001",
  "guardianPhone": "+966501234567",
  "primaryGuardianId": null,
  "authorizedGuardianIds": [],
  "status": "pending",
  "createdAt": "2025-07-09T00:00:00.000Z"
}

// 6. Create 'schools' collection
// Click "Start collection" -> Enter collection ID: "schools"

// 6. Add School:
// Document ID: "SCH_001"
// Fields:
{
  "name": "Al-Noor Elementary School",
  "address": "Riyadh, Saudi Arabia",
  "phone": "+966114567890",
  "createdAt": "2025-07-09T00:00:00.000Z"
}

// 🎯 TESTING INSTRUCTIONS:
// After adding this data, test your app with:
// • Phone: +966512345678 → Should link to Sara and Omar
// • Phone: +966587654321 → Should link to Fatima
// • Phone: +966501234567 → Should link to Ahmed
// • Phone: +966999999999 → Should show "No linked students yet"
