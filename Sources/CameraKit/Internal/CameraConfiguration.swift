import SwiftUI

struct CameraConfiguration: Equatable {
    var position: CameraPosition = .back
    var tapToFocus = true
    var tapToExpose = true
    var flashMode: CameraFlashMode = .auto
}

private struct CameraConfigurationKey: EnvironmentKey {
    static let defaultValue = CameraConfiguration()
}

extension EnvironmentValues {
    var cameraConfiguration: CameraConfiguration {
        get { self[CameraConfigurationKey.self] }
        set { self[CameraConfigurationKey.self] = newValue }
    }
}
