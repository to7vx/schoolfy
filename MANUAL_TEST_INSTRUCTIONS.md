# Manual Test Instructions

## If names still don't appear, try this:

### 1. Add Test Data to Firebase Console
1. Go to Firebase Console → Realtime Database → Data
2. Click on the + next to your database root
3. Set key: `pickupQueue`
4. Click the + next to pickupQueue
5. Set key: `2025-07-09` 
6. Click the + next to 2025-07-09
7. Set key: `pickup_manual_test`
8. Set value:
```json
{
  "studentId": "STU999",
  "studentName": "اختبار يدوي",
  "grade": "الصف الأول", 
  "time": "2025-07-09T16:55:00.000Z",
  "guardianName": "ولي أمر اختبار",
  "guardianPhone": "+966501234999"
}
```

### 2. Check Web Display
- The web display should immediately show the test student
- If it appears, the system is working correctly
- If not, there's a Firebase configuration issue

### 3. Test Mobile App
- After confirming manual data works, try the mobile app pickup button
- The new request should appear alongside the manual test data

## Expected Result
You should see a card with:
- Student name: اختبار يدوي
- Grade: الصف الأول  
- Time: Guardian arrived at 16:55
