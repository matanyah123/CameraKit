import SwiftUI

@available(iOS 17, macOS 14, *)
public enum CameraPosition: Sendable, Equatable {
    case front
    case back
}

@available(iOS 17, macOS 14, *)
public enum CameraFlashMode: Sendable, Equatable {
    case off
    case on
    case auto
}

@available(iOS 17, macOS 14, *)
public enum CameraPreviewContentMode: Sendable, Equatable {
    case fill
    case fit
}

@available(iOS 17, macOS 14, *)
public enum CameraSessionPreset: Sendable, Equatable {
    case photo
    case high
    case medium
    case low
}

@available(iOS 17, macOS 14, *)
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

    func torchEnabled(_ isEnabled: Bool) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.isTorchEnabled = isEnabled
        }
    }

    func pinchToZoom(_ isEnabled: Bool) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.isPinchToZoomEnabled = isEnabled
        }
    }

    func cameraSessionPreset(_ preset: CameraSessionPreset) -> some View {
        transformEnvironment(\.cameraConfiguration) { configuration in
            configuration.sessionPreset = preset
        }
    }

    func cameraPreviewContentMode(_ contentMode: CameraPreviewContentMode) -> some View {
        transformEnvironment(\.cameraPresentationConfiguration) { configuration in
            configuration.previewContentMode = contentMode
        }
    }

    func cameraCornerRadius(_ cornerRadius: CGFloat) -> some View {
        transformEnvironment(\.cameraPresentationConfiguration) { configuration in
            configuration.cornerRadius = cornerRadius
        }
    }

    func cameraPermissionDeniedContent<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        let view = AnyView(content())
        return transformEnvironment(\.cameraStatusContentConfiguration) { configuration in
            configuration.permissionDenied = view
        }
    }

    func cameraLoadingContent<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        let view = AnyView(content())
        return transformEnvironment(\.cameraStatusContentConfiguration) { configuration in
            configuration.loading = view
        }
    }

    func cameraUnsupportedContent<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        let view = AnyView(content())
        return transformEnvironment(\.cameraStatusContentConfiguration) { configuration in
            configuration.unsupported = view
        }
    }
}
