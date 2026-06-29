import AVFoundation
import Foundation

@MainActor
final class CameraStore: ObservableObject {
    @Published private(set) var authorizationState: AVAuthorizationStatus

    let session: AVCaptureSession
    let controlContext = CameraControlContext()

    private let output: CameraOutput
    private let manager: CameraManager

    private var latestConfiguration = CameraConfiguration()
    private var hasActivated = false

    init(output: CameraOutput) {
        self.output = output
        self.manager = CameraManager()
        self.session = manager.session
        self.authorizationState = AVCaptureDevice.authorizationStatus(for: .video)

        controlContext.capture = { [weak manager, weak self] in
            guard let self else { return }
            manager?.capturePhoto(flashMode: self.latestConfiguration.flashMode)
        }

        manager.onPhotoData = { [weak output] data in
            Task { @MainActor in
                output?.appendPhotoData(data)
            }
        }
    }

    func activate(with configuration: CameraConfiguration) {
        latestConfiguration = configuration

        if !hasActivated {
            hasActivated = true
            Task {
                await requestPermissionIfNeeded()
                applyConfiguration()
            }
            return
        }

        applyConfiguration()
    }

    func deactivate() {
        manager.stopSession()
    }

    func handlePreviewTap(at point: CGPoint) {
        manager.focusAndExpose(
            at: point,
            shouldFocus: latestConfiguration.tapToFocus,
            shouldExpose: latestConfiguration.tapToExpose
        )
    }

    private func requestPermissionIfNeeded() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            authorizationState = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .authorized : .denied
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        @unknown default:
            authorizationState = .restricted
        }
    }

    private func applyConfiguration() {
        controlContext.isCaptureAvailable = authorizationState == .authorized

        guard authorizationState == .authorized else {
            manager.stopSession()
            return
        }

        manager.configureIfNeeded(position: latestConfiguration.position)
        manager.startSession()
    }
}
