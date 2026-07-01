import AVFoundation
import Foundation

@available(iOS 17, macOS 14, *)
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

        bindControlActions()
        bindManagerCallbacks()
        syncAuthorizationState()
        syncContext()
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
        controlContext.isSessionRunning = false
        output.setStatus(.idle)
    }

    func handlePreviewTap(at point: CGPoint) {
        manager.focusAndExpose(
            at: point,
            shouldFocus: latestConfiguration.tapToFocus,
            shouldExpose: latestConfiguration.tapToExpose
        )
    }

    func handlePreviewPinch(scaleDelta: CGFloat) {
        guard latestConfiguration.isPinchToZoomEnabled else { return }
        let updatedZoom = controlContext.zoomFactor * scaleDelta
        setZoomFactor(updatedZoom)
    }

    private func requestPermissionIfNeeded() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch currentStatus {
        case .authorized:
            authorizationState = .authorized
        case .notDetermined:
            output.setStatus(.requestingPermission)
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .authorized : .denied
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        @unknown default:
            authorizationState = .restricted
        }

        syncAuthorizationState()
    }

    private func applyConfiguration() {
        syncAuthorizationState()
        syncContext()

        guard authorizationState == .authorized else {
            manager.stopSession()
            output.setStatus(.idle)
            return
        }

        manager.configureIfNeeded(latestConfiguration)
        manager.startSession()
        output.setStatus(.ready)
    }

    private func bindControlActions() {
        controlContext.captureAction = { [weak self] in
            self?.capture()
        }

        controlContext.switchCameraAction = { [weak self] in
            self?.switchCamera()
        }

        controlContext.setFlashModeAction = { [weak self] flashMode in
            self?.latestConfiguration.flashMode = flashMode
            self?.controlContext.flashMode = flashMode
        }

        controlContext.toggleTorchAction = { [weak self] in
            self?.toggleTorch()
        }

        controlContext.setZoomFactorAction = { [weak self] zoomFactor in
            self?.setZoomFactor(zoomFactor)
        }
    }

    private func bindManagerCallbacks() {
        manager.onPhotoData = { [weak self] data in
            Task { @MainActor in
                guard let self else { return }
                self.output.appendPhotoData(data)
                self.controlContext.isCapturingPhoto = false
            }
        }

        manager.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.apply(state: state)
            }
        }

        manager.onError = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.controlContext.isCapturingPhoto = false
                self.output.setError(error)
            }
        }
    }

    private func capture() {
        guard authorizationState == .authorized else { return }
        controlContext.isCapturingPhoto = true
        output.setStatus(.capturing)
        manager.capturePhoto(flashMode: latestConfiguration.flashMode)
    }

    private func switchCamera() {
        latestConfiguration.position = latestConfiguration.position == .back ? .front : .back
        latestConfiguration.isTorchEnabled = false
        controlContext.currentPosition = latestConfiguration.position
        controlContext.isTorchEnabled = false
        applyConfiguration()
    }

    private func toggleTorch() {
        let updatedValue = !latestConfiguration.isTorchEnabled
        latestConfiguration.isTorchEnabled = updatedValue
        controlContext.isTorchEnabled = updatedValue
        manager.setTorchEnabled(updatedValue)
    }

    private func setZoomFactor(_ zoomFactor: CGFloat) {
        manager.setZoomFactor(zoomFactor)
    }

    private func apply(state: CameraDeviceState) {
        controlContext.currentPosition = state.position
        controlContext.isSessionRunning = state.isSessionRunning
        controlContext.isFlashAvailable = state.isFlashAvailable
        controlContext.isTorchAvailable = state.isTorchAvailable
        controlContext.isSwitchCameraAvailable = state.isSwitchCameraAvailable
        controlContext.zoomFactor = state.zoomFactor
        controlContext.minZoomFactor = state.minZoomFactor
        controlContext.maxZoomFactor = state.maxZoomFactor
        controlContext.isTorchEnabled = latestConfiguration.isTorchEnabled && state.isTorchAvailable
        output.setStatus(state.isSessionRunning ? .ready : .idle)
    }

    private func syncAuthorizationState() {
        let state = CameraAuthorizationState(authorizationState)
        controlContext.authorizationState = state
        output.setAuthorizationState(state)
    }

    private func syncContext() {
        controlContext.currentPosition = latestConfiguration.position
        controlContext.flashMode = latestConfiguration.flashMode
        controlContext.isTorchEnabled = latestConfiguration.isTorchEnabled
        controlContext.isCaptureAvailable = authorizationState == .authorized
        controlContext.isPinchToZoomEnabled = latestConfiguration.isPinchToZoomEnabled
    }
}

@available(iOS 17, macOS 14, *)
private extension CameraAuthorizationState {
    init(_ authorizationStatus: AVAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        @unknown default:
            self = .restricted
        }
    }
}
