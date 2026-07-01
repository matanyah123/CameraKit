import SwiftUI

@available(iOS 17, macOS 14, *)
struct CameraPresentationConfiguration: Equatable {
    var cornerRadius: CGFloat = 20
    var previewContentMode: CameraPreviewContentMode = .fill
    var controlsAlignment: Alignment = .bottom
}

@available(iOS 17, macOS 14, *)
private struct CameraPresentationConfigurationKey: EnvironmentKey {
    static let defaultValue = CameraPresentationConfiguration()
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
    var cameraPresentationConfiguration: CameraPresentationConfiguration {
        get { self[CameraPresentationConfigurationKey.self] }
        set { self[CameraPresentationConfigurationKey.self] = newValue }
    }
}
