# CameraKit

`CameraKit` is a lightweight SwiftUI camera package for when you want a real in-app camera instead of wrapping UIKit yourself every time.

It gives you:

- A drop-in `Camera` preview view
- Photo capture with an observable `CameraOutput`
- Reusable controls for shutter, flash, torch, zoom, and camera switching
- A `CameraReader` for building fully custom camera chrome
- Modifiers for session behavior, preview layout, and fallback content

## Requirements

- iOS 17+
- Add `NSCameraUsageDescription` to your app's `Info.plist`

## Installation

Add the package in Xcode or with Swift Package Manager:

```swift
.package(url: "https://github.com/your-name/CameraKit.git", branch: "main")
```

## Quick Start

```swift
import SwiftUI
import CameraKit

struct CameraScreen: View {
    @State private var output = CameraOutput()

    var body: some View {
        Camera(output: output) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .cameraPosition(.back)
        .flashMode(.auto)
        .tapToFocus(true)
        .tapToExpose(true)
        .pinchToZoom(true)
        .cameraControls {
            HStack {
                CameraFlashButton()
                Spacer()
                CameraShutterButton()
                Spacer()
                CameraSwitchButton()
            }
        }
    }
}
```

## Building Custom UI

Use `CameraReader` when you want the camera state and actions for your own controls.

```swift
import SwiftUI
import CameraKit

struct CustomCameraView: View {
    @State private var output = CameraOutput()

    var body: some View {
        Camera(output: output) {
            Color.clear
        }
        .cameraControls(alignment: .bottom) {
            CameraReader { camera in
                VStack(spacing: 16) {
                    HStack {
                        Button(camera.flashMode == .on ? "Flash On" : "Flash") {
                            camera.cycleFlashMode()
                        }

                        Spacer()

                        if let lastPhoto = output.lastPhoto {
                            CameraThumbnailView(photo: lastPhoto) { _ in
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 52, height: 52)
                            }
                        }
                    }

                    HStack {
                        Button("0.5x") {
                            camera.setZoomFactor(0.5)
                        }

                        CameraShutterButton()

                        Button("Flip") {
                            camera.switchCamera()
                        }
                    }
                }
                .padding()
                .foregroundStyle(.white)
            }
        }
    }
}
```

## Camera Output

`CameraOutput` is your observable capture model.

```swift
@State private var output = CameraOutput()
```

Available properties:

- `photos: [CameraPhoto]`
- `lastPhoto: CameraPhoto?`
- `authorizationState: CameraAuthorizationState`
- `status: CameraStatus`
- `lastError: CameraError?`

Available methods:

- `removeAllPhotos()`

`CameraPhoto` includes:

- `id: UUID`
- `imageData: Data`
- `capturedAt: Date`
- `uiImage: UIImage?` on UIKit platforms

## Reusable Controls

Built-in controls:

- `CameraShutterButton()`
- `CameraSwitchButton()`
- `CameraFlashButton()`
- `CameraTorchButton()`
- `CameraZoomControl()`
- `CameraThumbnailView(photo:content:)`

`CameraReader` exposes `CameraControlContext` with:

- `authorizationState`
- `currentPosition`
- `flashMode`
- `isTorchEnabled`
- `isSessionRunning`
- `isCaptureAvailable`
- `isCapturingPhoto`
- `isSwitchCameraAvailable`
- `isTorchAvailable`
- `isFlashAvailable`
- `zoomFactor`
- `minZoomFactor`
- `maxZoomFactor`
- `isPinchToZoomEnabled`
- `supportedFlashModes`

Actions available on `CameraControlContext`:

- `capture()`
- `switchCamera()`
- `setFlashMode(_:)`
- `cycleFlashMode()`
- `toggleTorch()`
- `setZoomFactor(_:)`
- `zoomIn(step:)`
- `zoomOut(step:)`

## View Modifiers

Behavior:

- `.cameraPosition(_:)`
- `.flashMode(_:)`
- `.torchEnabled(_:)`
- `.tapToFocus(_:)`
- `.tapToExpose(_:)`
- `.pinchToZoom(_:)`
- `.cameraSessionPreset(_:)`

Presentation:

- `.cameraControls(alignment:_:)`
- `.cameraPreviewContentMode(_:)`
- `.cameraCornerRadius(_:)`

Fallback content:

- `.cameraPermissionDeniedContent { ... }`
- `.cameraLoadingContent { ... }`
- `.cameraUnsupportedContent { ... }`

## Public Enums

- `CameraPosition`: `.front`, `.back`
- `CameraFlashMode`: `.off`, `.on`, `.auto`
- `CameraPreviewContentMode`: `.fill`, `.fit`
- `CameraSessionPreset`: `.photo`, `.high`, `.medium`, `.low`
- `CameraAuthorizationState`: `.notDetermined`, `.restricted`, `.denied`, `.authorized`

`CameraStatus`:

- `.idle`
- `.requestingPermission`
- `.ready`
- `.capturing`
- `.photoCaptured(CameraPhoto)`
- `.failed(CameraError)`

`CameraError`:

- `.cameraUnavailable(CameraPosition)`
- `.cannotAddInput`
- `.cannotAddOutput`
- `.configurationFailed`
- `.captureFailed`
- `.focusFailed`
- `.torchUnavailable`

## Notes

- The SwiftUI preview and the iOS Simulator do not provide a live camera feed.
- `flashMode` only affects still photo capture.
- Torch availability depends on the active camera.
