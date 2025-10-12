# Pre-Live Setup Feature Documentation

## Overview
Added a comprehensive pre-live setup page that allows users to configure camera and screen sharing options before starting a live stream.

## Features Implemented

### 1. **Pre-Live Setup Page** (`lib/features/live/pre_live_setup_page.dart`)

#### Camera Controls
- **Camera On/Off Toggle**: Users can enable or disable their camera before going live
- **Camera Preview**: Live preview of the camera feed when enabled
- **Camera Flip**: Switch between front and back cameras (if multiple cameras available)
- **Visual Feedback**: Shows "Camera Off" screen when disabled

#### Screen Share Controls
- **Screen Share Toggle**: Enable/disable screen sharing (placeholder implementation)
- **Visual Indicator**: Active state shown with gradient button
- **Confirmation Toast**: Shows feedback when toggling screen share

#### UI Elements
- **Camera Preview**: Full-screen camera preview with gradient overlay
- **Control Buttons**: Three circular buttons for camera, flip, and screen share
- **Info Text**: Dynamic text showing what will be shared (camera, screen, or both)
- **Go Live Button**: Large, prominent button with app theme gradient
- **Close Button**: Exit setup without starting live

#### Visual Design
- Black background with gradient overlay
- Glassmorphic control buttons with app theme colors
- Active state with gradient and glow effects
- Responsive layout adapting to screen size

### 2. **Live Page Updates** (`lib/features/live/go_live_page.dart`)

#### New Parameters
```dart
class GoLivePage extends StatefulWidget {
  const GoLivePage({
    super.key,
    this.cameraEnabled = true,      // Default: camera on
    this.screenShareEnabled = false, // Default: screen share off
  });
}
```

#### Camera Initialization
- Skips camera initialization if `cameraEnabled` is false
- Shows "Camera Off" message in video feed area
- Audio-only stream when camera is disabled

#### Screen Share Indicator
- Green badge appears in top-right corner when screen sharing is active
- Shows "Screen Sharing" text with screen share icon
- Positioned to not overlap with other UI elements

### 3. **Add Page Updates** (`lib/features/add/add_page.dart`)

#### Modified Flow
1. User clicks "Create Live" button
2. Confirmation dialog appears
3. Dialog text: "Setup your camera and screen sharing options before going live"
4. On confirmation, navigates to `PreLiveSetupPage` instead of directly to live
5. Button text changed from "Start Live" to "Setup Live"

## User Flow

```
Create Live Button
    ↓
Confirmation Dialog
    ↓
Pre-Live Setup Page
    ├─ Toggle Camera (On/Off)
    ├─ Flip Camera (if multiple cameras)
    ├─ Toggle Screen Share (On/Off)
    └─ View Live Preview
    ↓
Go Live Now Button
    ↓
Live Streaming Page
    ├─ Camera feed (if enabled)
    ├─ Screen share indicator (if enabled)
    └─ All live controls
```

## Implementation Details

### Camera Management
```dart
// Pre-Live Setup
- Initializes camera controller with preview
- User can toggle camera on/off before live
- User can switch between cameras
- Disposes camera before navigating to live page

// Live Page
- Re-initializes camera based on cameraEnabled flag
- Shows camera-off state if disabled
- Continues with existing camera controls
```

### Screen Share Status
```dart
// Currently a placeholder - real implementation requires platform-specific code
- Toggle updates state and shows feedback
- Status passed to live page via constructor
- Visual indicator shown during live stream
```

### Benefits
1. **User Control**: Configure settings before going live
2. **Preview**: See how you'll appear before streaming
3. **Confidence**: Test camera and settings in private
4. **Professional**: Clean setup process like major streaming platforms
5. **Flexible**: Support audio-only, camera-only, or camera + screen share

## Technical Notes

### Screen Sharing Implementation
The current implementation provides the UI and state management for screen sharing, but actual screen capture requires platform-specific implementation:

- **Android**: Would need `flutter_screen_recording` or similar package
- **iOS**: Would need `ReplayKit` integration
- **Web**: Would use `getDisplayMedia()` browser API

The infrastructure is in place - just needs platform-specific capture code.

### State Management
- Camera state: Managed in PreLiveSetupPage, passed to GoLivePage
- Screen share state: Boolean flag passed through constructor
- Both states immutable after live starts

### Error Handling
- Camera permission errors shown with retry button
- Camera initialization errors displayed with message
- Graceful fallback to audio-only if camera fails

## Future Enhancements

1. **Screen Share Implementation**: Add actual screen capture functionality
2. **Settings Persistence**: Remember user's preferred settings
3. **Audio Test**: Add microphone test before going live
4. **Beauty Filters**: Add filters/effects in preview
5. **Title & Description**: Allow setting live stream info before starting
6. **Thumbnail Selection**: Choose stream thumbnail
7. **Privacy Settings**: Who can view (public/followers/friends)
8. **Scheduled Lives**: Schedule live streams for later

## Files Modified

1. **Created**:
   - `lib/features/live/pre_live_setup_page.dart` (443 lines)

2. **Modified**:
   - `lib/features/live/go_live_page.dart`:
     - Added constructor parameters for camera/screen share
     - Added screen share indicator badge
     - Updated camera initialization logic
   
   - `lib/features/add/add_page.dart`:
     - Changed navigation to PreLiveSetupPage
     - Updated dialog text for setup flow

## Testing Checklist

- [ ] Camera toggle works correctly
- [ ] Camera preview shows when enabled
- [ ] Camera flip switches between cameras
- [ ] Screen share toggle updates state
- [ ] "Go Live Now" button navigates to live page
- [ ] Close button exits setup page
- [ ] Camera state passed correctly to live page
- [ ] Screen share indicator appears in live
- [ ] Audio-only works when camera disabled
- [ ] Error messages display properly
- [ ] Layout responsive on different screens

## Known Limitations

1. Screen sharing is a placeholder (needs platform implementation)
2. Camera flipping only works with multiple cameras
3. No settings persistence between sessions
4. No preview of what screen share will capture
