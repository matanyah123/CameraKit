import SwiftUI

public enum CameraPosition: Sendable, Equatable {
    case front
    case back
}

public enum CameraFlashMode: Sendable, Equatable {
    case off
    case on
    case auto
}

public extension View {
    func cameraPosition(_ position: CameraPosition) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.position = position
        }
    }

    func tapToFocus(_ isEnabled: Bool) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.tapToFocus = isEnabled
        }
    }

    func tapToExpose(_ isEnabled: Bool) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.tapToExpose = isEnabled
        }
    }

    func flashMode(_ flashMode: CameraFlashMode) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.flashMode = flashMode
        }
    }
}
