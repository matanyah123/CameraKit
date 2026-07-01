import SwiftUI

@available(iOS 17, macOS 14, *)
public struct Camera<Overlay: View>: View {
    @Environment(\.cameraConfiguration) private var configuration
    @Environment(\.cameraControlsContent) private var controls
    @Environment(\.cameraPresentationConfiguration) private var presentation
    @Environment(\.cameraStatusContentConfiguration) private var statusContent

    @StateObject private var store: CameraStore

    private let overlay: Overlay

    public init(
        output: CameraOutput,
        @ViewBuilder overlay: () -> Overlay
    ) {
        _store = StateObject(wrappedValue: CameraStore(output: output))
        self.overlay = overlay()
    }

    public var body: some View {
        ZStack {
            switch store.authorizationState {
            case .authorized:
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    ContentUnavailableView(
                        "Camera is not supported in Preview",
                        systemImage: "camera.slash"
                    )
                    .labelStyle(.titleAndIcon)
                } else {
                    #if targetEnvironment(simulator)
                    unsupportedContent(message: "Camera is not supported in Simulator")
                    #else
                    CameraPreview(
                        session: store.session,
                        isTapGestureEnabled: configuration.tapToFocus || configuration.tapToExpose,
                        isPinchToZoomEnabled: configuration.isPinchToZoomEnabled,
                        contentMode: presentation.previewContentMode,
                        onTap: store.handlePreviewTap(at:),
                        onPinch: store.handlePreviewPinch(scaleDelta:)
                    )
                    .overlay {
                        overlay
                    }
                    #endif
                }
                
                if let controls {
                    controlsContainer(controls)
                }
            case .denied:
                permissionDeniedContent
            case .notDetermined, .restricted:
                loadingContent
            @unknown default:
                loadingContent
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: presentation.cornerRadius, style: .continuous))
        .environment(\.cameraControlContext, store.controlContext)
        .onAppear {
            store.activate(with: configuration)
        }
        .onDisappear {
            store.deactivate()
        }
        .onChange(of: configuration) { _, newValue in
            store.activate(with: newValue)
        }
    }
}

@available(iOS 17, macOS 14, *)
public extension Camera where Overlay == EmptyView {
    init(output: CameraOutput) {
        self.init(output: output) {
            EmptyView()
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension Camera {
    var loadingContent: some View {
        Group {
            if let custom = statusContent.loading {
                custom
            } else {
                CameraLoadingView()
            }
        }
    }

    var permissionDeniedContent: some View {
        Group {
            if let custom = statusContent.permissionDenied {
                custom
            } else {
                CameraPermissionDeniedView()
            }
        }
    }

    func unsupportedContent(message: String) -> some View {
        Group {
            if let custom = statusContent.unsupported {
                custom
            } else {
                ContentUnavailableView(
                    message,
                    systemImage: "camera.slash"
                )
                .labelStyle(.titleAndIcon)
            }
        }
    }

    func controlsContainer(_ controls: AnyView) -> some View {
        ZStack(alignment: presentation.controlsAlignment) {
            Color.clear
            controls
                .padding()
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct CameraLoadingView: View {
    var body: some View {
        ZStack {
            Color.black

            ProgressView()
                .tint(.white)
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct CameraPermissionDeniedView: View {
    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 8) {
                Text("Camera Access Needed")
                    .font(.headline)

                Text("Enable camera access in Settings to show the live preview.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .foregroundStyle(.white)
        }
    }
}
