# 🧪 Back Navigation Testing Checklist

## Quick Test (30 seconds)

### ✅ Test 1: Exit from Home
```
1. Open app
2. You're on Home screen
3. Press back button once
   Expected: See snackbar "Press back again to exit"
4. Press back button again (within 2 seconds)
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 2: Profile → Home → Exit
```
1. Open app
2. Tap Profile tab (bottom nav)
3. Press back button
   Expected: Navigate to Home, see "Press back again to exit"
4. Press back button again (within 2 seconds)
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 3: Search → Home → Exit
```
1. Open app
2. Tap Search tab
3. Press back button
   Expected: Navigate to Home, see "Press back again to exit"
4. Press back button again (within 2 seconds)
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 4: Reels → Home → Exit
```
1. Open app
2. Tap Reels tab
3. Press back button
   Expected: Navigate to Home, see "Press back again to exit"
4. Press back button again (within 2 seconds)
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

## Advanced Tests

### ✅ Test 5: Double-Tap Timeout
```
1. Open app (Home screen)
2. Press back (see message)
3. Wait 3 seconds (timeout is 2 seconds)
4. Press back again
   Expected: Shows message again, does NOT exit
5. Press back immediately
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 6: Gesture Navigation (Android)
```
1. Open app
2. Go to Profile tab
3. Swipe from left edge (gesture)
   Expected: Navigate to Home
4. Swipe from left edge again
   Expected: See "Press back again to exit"
5. Swipe from left edge again
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 7: Multiple Tab Switches
```
1. Open app
2. Go to Profile
3. Press back → Home
4. Go to Search
5. Press back → Home
6. Go to Reels
7. Press back → Home
8. Press back → See exit message
9. Press back → Exit
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 8: Secondary Screen Navigation
```
1. Open app
2. Tap on a post (if available)
3. Press back
   Expected: Return to Home feed (normal back)
4. Open post again, open comments
5. Press back
   Expected: Close comments, stay on post
6. Press back
   Expected: Return to Home
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 9: Story Creation Flow
```
1. Open app
2. Tap "+" (create story/post)
3. Press back
   Expected: Return to Home
4. Press back
   Expected: See "Press back again to exit"
5. Press back
   Expected: App exits
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 10: Rapid Back Presses
```
1. Open app
2. Go to Profile
3. Quickly press back 3 times rapidly
   Expected: 
   - First press: Navigate to Home
   - Second press: Show exit message
   - Third press: Exit app
```
**Status:** ⬜ Pass / ⬜ Fail

---

## Edge Cases

### ✅ Test 11: Back From Deep Link
```
1. Open app from notification (deep link to post)
2. Press back
   Expected: Navigate to Home (not exit)
3. Press back twice
   Expected: Exit app
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 12: Minimized App Resume
```
1. Open app (Home screen)
2. Press back once (see message)
3. Press home button (minimize app)
4. Wait 5 seconds
5. Open app again
6. Press back
   Expected: Shows message again (timer reset)
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 13: Multiple Snackbars
```
1. Open app
2. Profile → Back (see snackbar)
3. Immediately go to Search
4. Search → Back (see new snackbar)
   Expected: Old snackbar clears, new one shows
```
**Status:** ⬜ Pass / ⬜ Fail

---

## Visual Verification

### ✅ Snackbar Appearance
```
Expected Design:
┌─────────────────────────────────────┐
│  ℹ️  Press back again to exit       │
└─────────────────────────────────────┘

Check:
⬜ Icon shows (info or home)
⬜ Text is readable (white on black87)
⬜ Rounded corners (8px)
⬜ Bottom floating position
⬜ Proper margins (16px)
⬜ Dismisses after 2 seconds
```

---

## Performance Tests

### ✅ Test 14: No Lag
```
1. Open app
2. Rapidly switch between tabs
3. Press back from each tab
   Expected: No lag, instant navigation
```
**Status:** ⬜ Pass / ⬜ Fail

---

### ✅ Test 15: Memory Leak Check
```
1. Open app
2. Perform 50 back button presses (various screens)
3. Check Android Studio Profiler
   Expected: No memory increase, stable performance
```
**Status:** ⬜ Pass / ⬜ Fail

---

## Platform-Specific Tests

### Android Tests

#### ✅ Test 16: Physical Back Button
```
Device: Android phone with physical back button
1. Open app
2. Go to Profile
3. Press physical back button
   Expected: Navigate to Home
```
**Status:** ⬜ Pass / ⬜ Fail

---

#### ✅ Test 17: Navigation Gesture (Android 10+)
```
Device: Android 10+ with gesture navigation
1. Open app → Profile
2. Swipe from left or right edge
   Expected: Navigate to Home
```
**Status:** ⬜ Pass / ⬜ Fail

---

### iOS Tests (if applicable)

#### ✅ Test 18: Swipe Back Gesture
```
Device: iPhone/iPad
1. Open app → Profile
2. Swipe from left edge
   Expected: Navigate to Home
```
**Status:** ⬜ Pass / ⬜ Fail

---

## Comparison Test (Instagram-like behavior)

### ✅ Test 19: Compare with Instagram
```
Instagram Behavior:
1. Open Instagram
2. Go to Profile
3. Press back → Home
4. Press back twice → Exit

Your App Behavior:
1. Open your app
2. Go to Profile
3. Press back → Home ✅
4. Press back twice → Exit ✅

Match: ⬜ Yes / ⬜ No
```

---

## Final Checklist

### Core Functionality
- ⬜ Double-tap to exit from Home works
- ⬜ Single back from tabs navigates to Home
- ⬜ Exit message shows correctly
- ⬜ 2-second timeout works
- ⬜ Gesture navigation supported
- ⬜ No crashes or errors

### User Experience
- ⬜ Snackbar is visible and readable
- ⬜ Navigation feels smooth
- ⬜ No unexpected exits
- ⬜ Consistent behavior across screens

### Performance
- ⬜ No lag or delays
- ⬜ No memory leaks
- ⬜ Battery usage normal

### Edge Cases
- ⬜ Works after app minimize/resume
- ⬜ Works with deep links
- ⬜ Works with rapid presses
- ⬜ Snackbars don't overlap

---

## Issue Reporting Template

If you find a bug:

```
**Issue:** [Brief description]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Device Info:**
- Device: [e.g., Pixel 6]
- Android Version: [e.g., Android 14]
- App Version: [Your version]

**Screenshots/Video:**
[If applicable]
```

---

## Success Criteria

### ✅ All Tests Must Pass:
- [ ] 10/10 Quick Tests passed
- [ ] 9/9 Advanced Tests passed
- [ ] 5/5 Edge Cases passed
- [ ] 3/3 Performance Tests passed
- [ ] Core Functionality checklist complete
- [ ] User Experience checklist complete

### 🎉 When All Tests Pass:
**Your back navigation system is production-ready!**

---

## Debug Commands

If issues occur:

### Check Current Route
```dart
// Add to any screen's build method
print('Current route: ${GoRouterState.of(context).uri.path}');
```

### Check Main Screen Detection
```dart
// Add to back_button_handler.dart
print('Is main screen: ${_mainScreens.contains(currentLocation)}');
print('Current location: $currentLocation');
```

### Check Double-Tap Timer
```dart
// Add to back_button_handler.dart
print('Last back press: $_lastBackPress');
print('Time diff: ${DateTime.now().difference(_lastBackPress ?? DateTime.now())}');
```

---

## Quick Fix Reference

| Issue | Quick Fix |
|-------|-----------|
| Back button does nothing | Check `PopScope` wrapping |
| Always exits immediately | Verify route spelling in `_mainScreens` |
| Snackbar not showing | Ensure `Scaffold` exists |
| Timer not resetting | Call `BackButtonHandler.reset()` on navigation |
| Gesture not working | Check Android gesture settings |

---

**Last Updated:** October 21, 2025
**Tested On:** [Your device]
**Status:** ⬜ Testing / ⬜ Passed / ⬜ Issues Found
