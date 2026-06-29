import SwiftUI

public struct Camera<Overlay: View>: View {
    @Environment(\.cameraConfiguration) private var configuration
    @Environment(\.cameraControlsContent) private var controls

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
                CameraPreview(
                    session: store.session,
                    isTapGestureEnabled: configuration.tapToFocus || configuration.tapToExpose,
                    onTap: store.handlePreviewTap(at:)
                )
                .overlay {
                    overlay
                }

                if let controls {
                    VStack {
                        Spacer()
                        controls
                    }
                    .padding()
                }
            case .denied:
                CameraPermissionDeniedView()
            case .notDetermined, .restricted:
                CameraLoadingView()
            @unknown default:
                CameraLoadingView()
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

public extension Camera where Overlay == EmptyView {
    init(output: CameraOutput) {
        self.init(output: output) {
            EmptyView()
        }
    }
}

private struct CameraLoadingView: View {
    var body: some View {
        ZStack {
            Color.black

            ProgressView()
                .tint(.white)
        }
    }
}

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
