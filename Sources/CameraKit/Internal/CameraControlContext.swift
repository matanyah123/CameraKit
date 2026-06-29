import SwiftUI

final class CameraControlContext: @unchecked Sendable {
    var isCaptureAvailable = false
    var capture: () -> Void = {}
}

private struct CameraControlContextKey: EnvironmentKey {
    static let defaultValue = CameraControlContext()
}

private struct CameraControlsContentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: AnyView? = nil
}

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
