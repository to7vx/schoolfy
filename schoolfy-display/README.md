# Schoolfy Pickup Display System## 🖥️ OverviewA real-time web display that shows students whose guardians have arrived for pickup. This system displays students grouped by grade with live updates from Firebase Realtime Database.## 🚀 Features### ✅ **Real-time Updates**- Live connection to Firebase Realtime Database- Automatic updates without page refresh- Connection status indicator (LIVE/OFFLINE)### 📱 **Responsive Display**- Optimized for TVs, tablets, and monitors- Fullscreen layout with large, readable fonts- Grid layout that adapts to number of grades- Color-coded grade columns

### 👥 **Student Information**
- Student name and grade display
- Avatar with student initials
- Pickup time when guardian arrived
- "NEW" indicator for recent arrivals (within 5 minutes)

### 🎨 **Visual Design**
- Modern Material Design interface
- Grade-specific color coding:
  - Grade 1: Red
  - Grade 2: Blue
  - Grade 3: Green
  - Grade 4: Orange
  - Grade 5: Purple
  - Grade 6: Teal
- Clean, professional appearance suitable for schools

## 🛠️ **Setup Instructions**

### 1. **Install Dependencies**
```bash
cd pickup_display_web
flutter pub get
```

### 2. **Configure Firebase**
- Update `firebase_options.dart` with your actual Firebase project settings
- Enable Firebase Realtime Database in your Firebase console
- Set up database rules for read access

### 3. **Add Sample Data**
- Go to Firebase Console → Realtime Database
- Import the data from `sample_pickup_data.json`
- Or manually add the JSON structure to your database

### 4. **Run the Application**
```bash
# For development
flutter run -d chrome

# For production build
flutter build web
```

### 5. **Deploy to Firebase Hosting** (Optional)
```bash
firebase deploy --only hosting
```

## 📊 **Database Structure**

### **Firebase Realtime Database Path:**
```
pickupQueue/{date}/{pickup_id}
```

### **Entry Format:**
```json
{
  "studentId": "stu_001",
  "studentName": "Sara Ahmed", 
  "grade": "2A",
  "time": "2025-07-09T13:45:00.000Z",
  "guardianName": "Fatima Ahmed",
  "guardianPhone": "+966500000001"
}
```

## 🔧 **Integration with Mobile App**

### **Adding Pickup Request from Mobile:**
```dart
// In the mobile app (HomePage), modify the pickup button:
Future<void> _sendPickupRequest(Map<String, dynamic> student) async {
  final database = FirebaseDatabase.instance.ref();
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final pickupId = 'pickup_${DateTime.now().millisecondsSinceEpoch}';
  
  await database
    .child('pickupQueue')
    .child(todayKey)
    .child(pickupId)
    .set({
      'studentId': student['studentId'],
      'studentName': student['studentName'],
      'grade': student['grade'],
      'time': DateTime.now().toIso8601String(),
      'guardianName': 'Current Guardian',
      'guardianPhone': FirebaseAuth.instance.currentUser?.phoneNumber,
    });
}
```

## 📺 **Display Setup for Schools**

### **Hardware Requirements:**
- TV/Monitor with HDMI input
- Computer/tablet with web browser
- Stable internet connection

### **Browser Setup:**
1. Open Chrome or any modern browser
2. Navigate to the pickup display URL
3. Press F11 for fullscreen mode
4. Set browser to kiosk mode (optional)

---

**Ready for production use in schools! 🏫**
