# Auto-Cleanup Configuration for Pickup Display

## 🕒 CURRENT BEHAVIOR
- Pickup cards stay on display indefinitely
- Manual removal required via Firebase Console
- No automatic cleanup

## ⚙️ AUTO-CLEANUP OPTIONS

### Option 1: Simple Timer-Based Cleanup (RECOMMENDED)
**Duration**: 10 minutes (configurable)
**Behavior**: 
- Cards appear immediately when pickup requested
- After 10 minutes, cards automatically disappear
- Visual indicators show card age (green → orange → red)

### Option 2: Manual Cleanup Only
**Behavior**: 
- Cards stay until manually removed
- School staff removes cards when student picked up
- No automatic deletion

### Option 3: Hybrid Approach
**Behavior**: 
- Cards stay for 15 minutes automatically
- Visual urgency indicators (color changes)
- Manual override to remove earlier

## 🎯 RECOMMENDED IMPLEMENTATION

For most schools, **Option 1** is recommended:

```dart
// Auto-cleanup after 10 minutes
static const Duration autoCleanupDuration = Duration(minutes: 10);

// Visual indicators:
// 0-2 minutes: Green (fresh)
// 2-5 minutes: Orange (waiting)  
// 5+ minutes: Red (urgent)
```

## 📝 CONFIGURATION

To enable auto-cleanup:

1. **Web Display**: Automatically removes old entries
2. **Visual Cues**: Color-coded time indicators
3. **Configurable**: Easy to change cleanup duration

### Time Settings:
- **Fresh (Green)**: 0-2 minutes
- **Waiting (Orange)**: 2-5 minutes  
- **Urgent (Red)**: 5+ minutes
- **Auto-Delete**: After 10 minutes

## 🚀 IMPLEMENTATION STATUS

✅ **Currently**: Cards stay indefinitely (no auto-cleanup)
⏳ **Available**: Auto-cleanup implementation ready
🎛️ **Configurable**: Easy to enable/disable

Would you like me to implement auto-cleanup? The default would be:
- **10 minutes** until auto-removal
- **Color indicators** for card age
- **Configurable** timing via constants
