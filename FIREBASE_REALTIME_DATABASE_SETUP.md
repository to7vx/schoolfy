# Firebase Realtime Database Setup Instructions

## Setup Steps for Firebase Console

### 1. Enable Firebase Realtime Database
1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to **Realtime Database** in the left sidebar
4. Click **Create Database**
5. Choose your location (e.g., us-central1)
6. Start in **test mode** for now

### 2. Update Security Rules
1. In Realtime Database, go to the **Rules** tab
2. Replace the existing rules with:

```json
{
  "rules": {
    "pickupQueue": {
      ".read": true,
      ".write": "auth != null",
      "$date": {
        "$pickupId": {
          ".validate": "newData.hasChildren(['studentId', 'studentName', 'grade', 'time', 'guardianName']) && auth != null"
        }
      }
    }
  }
}
```

3. Click **Publish**

### 3. Get Database URL
1. In the Realtime Database overview, copy your database URL
2. It should look like: `https://your-project-id-default-rtdb.firebaseio.com/`
3. Make sure this URL is configured in your Flutter app's Firebase configuration

### 4. Test the Connection
After applying these rules:
1. Restart your Flutter app
2. Try the pickup request feature
3. You should see data appearing in the Realtime Database under `pickupQueue/YYYY-MM-DD/`

## Troubleshooting

### If you still get permission errors:
1. Verify the user is authenticated (signed in)
2. Check that Firebase Authentication is properly configured
3. Ensure the Realtime Database URL matches your project

### Alternative Rules (More Permissive for Testing):
If you want to test quickly, you can use these temporary rules:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
**⚠️ WARNING**: Only use this for testing - it allows anyone to read/write your database!

## Security Notes
- The production rules only allow authenticated users to write
- Anyone can read the pickup queue (needed for the display system)
- Data is validated to ensure required fields are present
- Consider adding more specific validation rules for production use
