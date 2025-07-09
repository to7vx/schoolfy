# Manual Test Data Setup for Firebase Console

## How to Add Test Data to Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: schoolfy-706ff
3. Go to Firestore Database

## Add Students Collection

### Create students collection with these documents:

**Document 1 (auto-generated ID):**
```
name: "Sara Al-Zanbaqi"
grade: "2A"
schoolId: "SCH_001"
guardianPhone: "+966512345678"
primaryGuardianId: null
authorizedGuardianIds: []
status: "pending"
createdAt: (timestamp - current time)
```

**Document 2 (auto-generated ID):**
```
name: "Omar Al-Zanbaqi"
grade: "4B"
schoolId: "SCH_001"
guardianPhone: "+966512345678"
primaryGuardianId: null
authorizedGuardianIds: []
status: "pending"
createdAt: (timestamp - current time)
```

**Document 3 (auto-generated ID):**
```
name: "Fatima Al-Rashid"
grade: "3C"
schoolId: "SCH_001"
guardianPhone: "+966587654321"
primaryGuardianId: null
authorizedGuardianIds: []
status: "pending"
createdAt: (timestamp - current time)
```

## Add Schools Collection

### Create schools collection with this document:

**Document ID: SCH_001**
```
name: "Al-Noor Elementary School"
address: "Riyadh, Saudi Arabia"
phone: "+966114567890"
createdAt: (timestamp - current time)
```

## Testing Phone Numbers:

After adding the data, test the app with these phone numbers:

- **+966512345678** - Should automatically link to Sara and Omar
- **+966587654321** - Should automatically link to Fatima
- **+966999999999** - Should show "No linked students yet"

## SMS Verification for Testing:

Firebase Auth in test mode allows you to use test phone numbers. In Firebase Console:
1. Go to Authentication > Settings > Phone Numbers for Testing
2. Add test phone numbers with verification codes:
   - +966512345678 → 123456
   - +966587654321 → 123456
   - +966999999999 → 123456

This allows you to test without real SMS.
