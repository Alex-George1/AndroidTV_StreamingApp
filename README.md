# Android TV Streaming App

A Flutter app for Android TV that displays categorized video content with D-pad navigation, full-screen playback, and ExoPlayer-based video streaming.

## Features

- **TV-Style Layout**: Horizontal category rows with focusable video cards
- **Full-Screen Playback**: ExoPlayer with remote control support (play/pause/seek/back)
- **D-Pad Navigation**: Optimized for TV remotes and D-pad input
- **Focus Animations**: 1.1x scale + purple glow on focus + autoplay
- **Dynamic Content**: Load videos from JSON asset (10+ videos across 4 categories)
- **Android & Phone Compatible**: Runs on both Android TV and Android phones

## Architecture

**MVVM + Provider**: Clean separation of concerns
- **Models**: `VideoItem`, `VideoCategory`
- **ViewModels**: `HomeViewModel`, `PlayerViewModel`
- **Views**: `HomeScreen`, `PlayerScreen`
- **Services**: `VideoService` (loads video catalog)

## Setup

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release
```

## Verification

```bash
flutter analyze     # Zero linting errors
flutter test        # 9 tests pass
```

## Project Structure

```
lib/
  main.dart                 # App entry point
  models/                   # Data models
  viewmodels/               # Business logic
  views/                    # Screen widgets
  widgets/                  # Reusable UI components
  services/                 # Data layer
assets/
  data/videos.json          # Video catalog
```

## Tech Stack

- **Flutter**: 3.41.2+
- **State Management**: Provider
- **Video Player**: ExoPlayer (via video_player)
- **Image Loading**: Flutter Image.network with timeout fallback
- **Linting**: flutter_lints

## Supported Platforms

- Android TV (primary target)
- Android Phone (landscape)
