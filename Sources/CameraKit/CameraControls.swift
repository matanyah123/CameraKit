import SwiftUI

@available(iOS 17, macOS 14, *)
public extension View {
    func cameraControls<Content: View>(
        alignment: Alignment = .bottom,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        transformEnvironment(\.cameraPresentationConfiguration) { configuration in
            configuration.controlsAlignment = alignment
        }
        .environment(\.cameraControlsContent, AnyView(content()))
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraReader<Content: View>: View {
    @Environment(\.cameraControlContext) private var context

    private let content: (CameraControlContext) -> Content

    public init(@ViewBuilder content: @escaping (CameraControlContext) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(context)
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraShutterButton: View {
    @Environment(\.cameraControlContext) private var context

    public init() {}

    public var body: some View {
        Button(action: context.capture) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 82, height: 82)

                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)
                    .scaleEffect(context.isCapturingPhoto ? 0.86 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!context.isCaptureAvailable || context.isCapturingPhoto)
        .opacity(context.isCaptureAvailable ? 1.0 : 0.55)
        .animation(.easeInOut(duration: 0.18), value: context.isCapturingPhoto)
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraSwitchButton: View {
    @Environment(\.cameraControlContext) private var context

    public init() {}

    public var body: some View {
        Button(action: context.switchCamera) {
            Label("Flip Camera", systemImage: "arrow.triangle.2.circlepath.camera")
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!context.isSwitchCameraAvailable)
        .opacity(context.isSwitchCameraAvailable ? 1 : 0.55)
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraFlashButton: View {
    @Environment(\.cameraControlContext) private var context

    public init() {}

    public var body: some View {
        Button(action: context.cycleFlashMode) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!context.isFlashAvailable)
        .opacity(context.isFlashAvailable ? 1 : 0.55)
    }

    private var iconName: String {
        switch context.flashMode {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.automatic.fill"
        }
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraTorchButton: View {
    @Environment(\.cameraControlContext) private var context

    public init() {}

    public var body: some View {
        Button(action: context.toggleTorch) {
            Image(systemName: context.isTorchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!context.isTorchAvailable)
        .opacity(context.isTorchAvailable ? 1 : 0.55)
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraZoomControl: View {
    @Environment(\.cameraControlContext) private var context

    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            Text("\(context.zoomFactor, format: .number.precision(.fractionLength(1)))x")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)

            Slider(
                value: Binding(
                    get: { context.zoomFactor },
                    set: { context.setZoomFactor($0) }
                ),
                in: context.minZoomFactor...max(context.maxZoomFactor, context.minZoomFactor),
                step: 0.1
            )
            .tint(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.35), in: Capsule())
    }
}

@available(iOS 17, macOS 14, *)
public struct CameraThumbnailView<Content: View>: View {
    private let photo: CameraPhoto?
    private let content: (CameraPhoto) -> Content

    public init(
        photo: CameraPhoto?,
        @ViewBuilder content: @escaping (CameraPhoto) -> Content
    ) {
        self.photo = photo
        self.content = content
    }

    public var body: some View {
        Group {
            if let photo {
                content(photo)
            }
        }
    }
}
