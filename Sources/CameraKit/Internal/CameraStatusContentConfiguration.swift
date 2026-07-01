import SwiftUI

@available(iOS 17, macOS 14, *)
struct CameraStatusContentConfiguration {
    var loading: AnyView?
    var permissionDenied: AnyView?
    var unsupported: AnyView?
}

@available(iOS 17, macOS 14, *)
private struct CameraStatusContentConfigurationKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue = CameraStatusContentConfiguration()
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
    var cameraStatusContentConfiguration: CameraStatusContentConfiguration {
        get { self[CameraStatusContentConfigurationKey.self] }
        set { self[CameraStatusContentConfigurationKey.self] = newValue }
    }
}
