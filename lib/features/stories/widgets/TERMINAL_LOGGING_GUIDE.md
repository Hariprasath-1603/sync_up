# 📟 Terminal Logging Guide - Square Story Row

## Overview
Real-time console output for debugging and monitoring story system.

## Log Format
```
[HH:MM:SS] 🎬 STORY: [Message]
```

## Emoji Legend

| Emoji | Meaning | Example |
|-------|---------|---------|
| 📱 | Initialization | Component started |
| 🔄 | Loading/Fetching | Getting data from Supabase |
| ✅ | Success | Operation completed |
| ❌ | Error | Something went wrong |
| ⚠️ | Warning | Non-critical issue |
| ℹ️ | Information | Status update |
| 👤 | User Info | Current user details |
| ▶️ | Start Action | Viewer/creator opened |
| ⏹️ | Stop Action | Viewer/creator closed |
| ➕ | Add/Create | Story creator opened |
| 🗑️ | Delete | Story deletion |
| 📦 | Archive | Story archiving |
| 📊 | Insights | Analytics requested |
| ⚙️ | Settings/Menu | Management options |
| 🆕 | New Content | Story inserted |
| 📝 | Update | Story modified |
| 🔔 | Subscription | Real-time setup |
| 🔴 | Disposal | Component destroyed |

## Event Categories

### 1. Lifecycle Events
```
[14:32:10] 🎬 STORY: 📱 Square Story Row initialized
[15:00:00] 🎬 STORY: 🔴 Square Story Row disposed
```

### 2. Data Fetching
```
[14:32:10] 🎬 STORY: 🔄 Fetching stories from Supabase...
[14:32:10] 🎬 STORY: 👤 Current user ID: a1b2c3d4...
[14:32:11] 🎬 STORY: ✅ Fetched 8 active stories
[14:32:11] 🎬 STORY: ✅ Current user has 3 story segment(s)
[14:32:11] 🎬 STORY: ℹ️ Current user has no active story
[14:32:11] 🎬 STORY: ✅ Loaded 4 other users' stories
```

### 3. Real-Time Events
```
[14:32:11] 🎬 STORY: 🔔 Subscribing to real-time story updates...
[14:32:11] 🎬 STORY: ✅ Real-time subscription active
[14:40:30] 🎬 STORY: 🆕 New story inserted - refreshing...
[14:45:00] 🎬 STORY: 🗑️ Story deleted - refreshing...
[14:50:00] 🎬 STORY: 📝 Story updated - refreshing...
```

### 4. User Actions
```
[14:35:22] 🎬 STORY: ➕ Opening story creator...
[14:37:15] 🎬 STORY: ⏹️ Story creator closed - refreshing data...
[14:42:05] 🎬 STORY: ▶️ Opening story viewer for john_doe's story
[14:42:05] 🎬 STORY: ▶️ Opening story viewer for own story
[14:42:35] 🎬 STORY: ⏹️ Story viewer closed - refreshing data...
```

### 5. Management Actions
```
[14:45:12] 🎬 STORY: ⚙️ Opening story management menu...
[14:45:18] 🎬 STORY: 📦 Archiving story...
[14:45:19] 🎬 STORY: ✅ Story archived successfully
[14:46:00] 🎬 STORY: 🗑️ Deleting story...
[14:46:01] 🎬 STORY: ✅ Story deleted successfully
[14:47:00] 🎬 STORY: 📊 Insights requested (coming soon)
```

### 6. Error Events
```
[14:50:00] 🎬 STORY: ❌ Error fetching stories: Connection timeout
[14:51:00] 🎬 STORY: ❌ Error archiving story: Permission denied
[14:52:00] 🎬 STORY: ❌ Error deleting story: Story not found
[14:53:00] 🎬 STORY: ⚠️ No authenticated user found
```

## Complete Session Example

```
[14:30:00] 🎬 STORY: 📱 Square Story Row initialized
[14:30:00] 🎬 STORY: 🔄 Fetching stories from Supabase...
[14:30:00] 🎬 STORY: 👤 Current user ID: a1b2c3d4...
[14:30:01] 🎬 STORY: ✅ Fetched 12 active stories
[14:30:01] 🎬 STORY: ℹ️ Current user has no active story
[14:30:01] 🎬 STORY: ✅ Loaded 5 other users' stories
[14:30:01] 🎬 STORY: 🔔 Subscribing to real-time story updates...
[14:30:01] 🎬 STORY: ✅ Real-time subscription active

[14:32:15] 🎬 STORY: ➕ Opening story creator...
[14:34:20] 🎬 STORY: ⏹️ Story creator closed - refreshing data...
[14:34:20] 🎬 STORY: 🔄 Fetching stories from Supabase...
[14:34:21] 🎬 STORY: ✅ Fetched 13 active stories
[14:34:21] 🎬 STORY: ✅ Current user has 1 story segment(s)
[14:34:21] 🎬 STORY: ✅ Loaded 5 other users' stories

[14:35:00] 🎬 STORY: 🆕 New story inserted - refreshing...
[14:35:00] 🎬 STORY: 🔄 Fetching stories from Supabase...
[14:35:01] 🎬 STORY: ✅ Fetched 14 active stories
[14:35:01] 🎬 STORY: ✅ Loaded 6 other users' stories

[14:36:10] 🎬 STORY: ▶️ Opening story viewer for alice_smith's story
[14:36:45] 🎬 STORY: ⏹️ Story viewer closed - refreshing data...
[14:36:45] 🎬 STORY: 🔄 Fetching stories from Supabase...

[14:40:00] 🎬 STORY: ▶️ Opening story viewer for own story
[14:40:30] 🎬 STORY: ⏹️ Story viewer closed - refreshing data...

[14:42:00] 🎬 STORY: ⚙️ Opening story management menu...
[14:42:10] 🎬 STORY: 📦 Archiving story...
[14:42:11] 🎬 STORY: ✅ Story archived successfully
[14:42:11] 🎬 STORY: 🔄 Fetching stories from Supabase...
[14:42:12] 🎬 STORY: ℹ️ Current user has no active story

[15:00:00] 🎬 STORY: 🔴 Square Story Row disposed
```

## Debugging Tips

### Check if Component is Active
```
grep "📱 Square Story Row initialized" terminal_output.log
```

### Monitor Fetch Operations
```
grep "🔄 Fetching" terminal_output.log
```

### Track User Actions
```
grep "▶️\|⏹️\|➕" terminal_output.log
```

### Find Errors Only
```
grep "❌" terminal_output.log
```

### Count Story Fetches
```
grep -c "✅ Fetched.*stories" terminal_output.log
```

### Monitor Real-Time Events
```
grep "🆕\|🗑️\|📝" terminal_output.log
```

## Log Implementation

### In Code
```dart
void _logToTerminal(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🎬 STORY: $message');
}

// Usage examples:
_logToTerminal('📱 Square Story Row initialized');
_logToTerminal('🔄 Fetching stories from Supabase...');
_logToTerminal('✅ Fetched ${stories.length} active stories');
_logToTerminal('❌ Error fetching stories: $e');
```

### Terminal Output Location

**Flutter Run:**
```bash
flutter run
# Logs appear in terminal
```

**VS Code Debug Console:**
- Run → Start Debugging (F5)
- Logs appear in "Debug Console" panel

**Android Studio:**
- Run → Debug
- Logs appear in "Run" tab at bottom

**Terminal Filtering:**
```bash
# Show only story logs
flutter run 2>&1 | grep "🎬 STORY"

# Save logs to file
flutter run 2>&1 | grep "🎬 STORY" > story_logs.txt
```

## Performance Impact

✅ **Minimal** - Simple print statements
✅ **No Network Calls** - Local logging only
✅ **Async Safe** - Doesn't block UI
✅ **Production Ready** - Can be left enabled

## Disable Logging (Optional)

### Option 1: Comment out method body
```dart
void _logToTerminal(String message) {
  // Disabled for production
  // final timestamp = DateTime.now().toString().substring(11, 19);
  // print('[$timestamp] 🎬 STORY: $message');
}
```

### Option 2: Add debug flag
```dart
static const bool _enableLogs = false; // Set to true to enable

void _logToTerminal(String message) {
  if (!_enableLogs) return;
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🎬 STORY: $message');
}
```

### Option 3: Use kDebugMode
```dart
import 'package:flutter/foundation.dart';

void _logToTerminal(String message) {
  if (!kDebugMode) return; // Only log in debug builds
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🎬 STORY: $message');
}
```

## Monitoring Checklist

✅ Component initialized successfully
✅ Stories fetched from database
✅ Current user state detected
✅ Real-time subscription active
✅ User actions logged correctly
✅ Errors reported with context
✅ Component disposed cleanly

---

**Terminal Logs**: ✅ Active  
**Format**: `[HH:MM:SS] 🎬 STORY: [Message]`  
**Impact**: Minimal (local print only)
