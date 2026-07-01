import SwiftUI

@available(iOS 17, macOS 14, *)
struct CameraConfiguration: Equatable {
    var position: CameraPosition = .back
    var tapToFocus = true
    var tapToExpose = true
    var flashMode: CameraFlashMode = .auto
    var isTorchEnabled = false
    var isPinchToZoomEnabled = true
    var sessionPreset: CameraSessionPreset = .photo
}

@available(iOS 17, macOS 14, *)
private struct CameraConfigurationKey: EnvironmentKey {
    static let defaultValue = CameraConfiguration()
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
    var cameraConfiguration: CameraConfiguration {
        get { self[CameraConfigurationKey.self] }
        set { self[CameraConfigurationKey.self] = newValue }
    }
}
