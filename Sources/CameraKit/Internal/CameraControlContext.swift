import SwiftUI
import Observation

@available(iOS 17, macOS 14, *)
@Observable
public final class CameraControlContext {
    public internal(set) var authorizationState: CameraAuthorizationState = .notDetermined
    public internal(set) var currentPosition: CameraPosition = .back
    public internal(set) var flashMode: CameraFlashMode = .auto
    public internal(set) var isTorchEnabled = false
    public internal(set) var isSessionRunning = false
    public internal(set) var isCaptureAvailable = false
    public internal(set) var isCapturingPhoto = false
    public internal(set) var isSwitchCameraAvailable = false
    public internal(set) var isTorchAvailable = false
    public internal(set) var isFlashAvailable = false
    public internal(set) var zoomFactor: CGFloat = 1
    public internal(set) var maxZoomFactor: CGFloat = 1
    public internal(set) var minZoomFactor: CGFloat = 1
    public internal(set) var isPinchToZoomEnabled = true

    var captureAction: () -> Void = {}
    var switchCameraAction: () -> Void = {}
    var setFlashModeAction: (CameraFlashMode) -> Void = { _ in }
    var toggleTorchAction: () -> Void = {}
    var setZoomFactorAction: (CGFloat) -> Void = { _ in }

    public init() {}

    public func capture() {
        captureAction()
    }

    public func switchCamera() {
        switchCameraAction()
    }

    public func setFlashMode(_ flashMode: CameraFlashMode) {
        setFlashModeAction(flashMode)
    }

    public func cycleFlashMode() {
        let modes = supportedFlashModes

        guard !modes.isEmpty else { return }

        let currentIndex = modes.firstIndex(of: flashMode) ?? 0
        let nextIndex = (currentIndex + 1) % modes.count
        setFlashMode(modes[nextIndex])
    }

    public func toggleTorch() {
        toggleTorchAction()
    }

    public func setZoomFactor(_ zoomFactor: CGFloat) {
        setZoomFactorAction(zoomFactor)
    }

    public func zoomIn(step: CGFloat = 0.5) {
        setZoomFactor(zoomFactor + step)
    }

    public func zoomOut(step: CGFloat = 0.5) {
        setZoomFactor(zoomFactor - step)
    }

    public var supportedFlashModes: [CameraFlashMode] {
        isFlashAvailable ? [.off, .on, .auto] : [.off]
    }
}

@available(iOS 17, macOS 14, *)
private struct CameraControlContextKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = CameraControlContext()
}

@available(iOS 17, macOS 14, *)
private struct CameraControlsContentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: AnyView? = nil
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
    var cameraControlContext: CameraControlContext {
        get { self[CameraControlContextKey.self] }
        set { self[CameraControlContextKey.self] = newValue }
    }

    var cameraControlsContent: AnyView? {
        get { self[CameraControlsContentKey.self] }
        set { self[CameraControlsContentKey.self] = newValue }
    }
}
