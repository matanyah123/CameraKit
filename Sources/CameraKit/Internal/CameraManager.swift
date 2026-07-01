import AVFoundation
import CoreGraphics
import Foundation

@available(iOS 17, macOS 14, *)
struct CameraDeviceState: Sendable, Equatable {
    var position: CameraPosition
    var isSessionRunning = false
    var isFlashAvailable = false
    var isTorchAvailable = false
    var isSwitchCameraAvailable = false
    var zoomFactor: CGFloat = 1
    var minZoomFactor: CGFloat = 1
    var maxZoomFactor: CGFloat = 1
}

@available(iOS 17, macOS 14, *)
final class CameraManager: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()

    var onPhotoData: (Data) -> Void = { _ in }
    var onStateChange: @Sendable (CameraDeviceState) -> Void = { _ in }
    var onError: @Sendable (CameraError) -> Void = { _ in }

    private let sessionQueue = DispatchQueue(label: "CameraKit.CameraManager")
    private let photoOutput = AVCapturePhotoOutput()

    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: CameraPosition = .back
    private var currentState = CameraDeviceState(position: .back)
    private var isConfigured = false
    private var captureDelegates: [PhotoCaptureDelegate] = []

    func configureIfNeeded(_ configuration: CameraConfiguration) {
        sessionQueue.async {
            if self.isConfigured {
                self.applySessionPreset(configuration.sessionPreset)
                self.replaceInputIfNeeded(position: configuration.position)
                self.setTorchEnabled(configuration.isTorchEnabled)
                self.setZoomFactor(self.currentState.zoomFactor)
                return
            }

            self.session.beginConfiguration()
            self.applySessionPreset(configuration.sessionPreset)

            guard self.session.canAddOutput(self.photoOutput) else {
                self.session.commitConfiguration()
                self.reportError(.cannotAddOutput)
                return
            }

            self.session.addOutput(self.photoOutput)
            self.replaceInputIfNeeded(position: configuration.position)
            self.session.commitConfiguration()
            self.isConfigured = true

            self.setTorchEnabled(configuration.isTorchEnabled)
            self.reportState()
        }
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            self.currentState.isSessionRunning = self.session.isRunning
            self.reportState()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            self.currentState.isSessionRunning = self.session.isRunning
            self.reportState()
        }
    }

    func capturePhoto(flashMode: CameraFlashMode) {
        sessionQueue.async {
            let settings = AVCapturePhotoSettings()

            if self.currentInput?.device.isFlashAvailable == true {
                settings.flashMode = flashMode.avFlashMode
            }

            var delegate: PhotoCaptureDelegate?
            delegate = PhotoCaptureDelegate { [weak self] data in
                guard let self else { return }

                if let data {
                    self.onPhotoData(data)
                } else {
                    self.reportError(.captureFailed)
                }

                if let delegate {
                    self.removeCaptureDelegate(delegate)
                }
            }

            if let delegate {
                self.captureDelegates.append(delegate)
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    func focusAndExpose(
        at devicePoint: CGPoint,
        shouldFocus: Bool,
        shouldExpose: Bool
    ) {
        sessionQueue.async {
            guard
                let device = self.currentInput?.device,
                shouldFocus || shouldExpose
            else {
                return
            }

            do {
                try device.lockForConfiguration()

                if shouldFocus, device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    }
                }

                if shouldExpose, device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }

                device.unlockForConfiguration()
            } catch {
                self.reportError(.focusFailed)
            }
        }
    }

    func setTorchEnabled(_ isEnabled: Bool) {
        sessionQueue.async {
            guard let device = self.currentInput?.device else { return }
            guard device.hasTorch else {
                if isEnabled {
                    self.reportError(.torchUnavailable)
                }
                return
            }

            do {
                try device.lockForConfiguration()
                device.torchMode = isEnabled ? .on : .off
                device.unlockForConfiguration()
                self.currentState.isTorchAvailable = device.hasTorch
                self.reportState()
            } catch {
                self.reportError(.torchUnavailable)
            }
        }
    }

    func setZoomFactor(_ zoomFactor: CGFloat) {
        sessionQueue.async {
            guard let device = self.currentInput?.device else { return }

            #if os(iOS)
            let minZoomFactor = max(device.minAvailableVideoZoomFactor, 1)
            let maxZoomFactor = max(min(device.maxAvailableVideoZoomFactor, 10), minZoomFactor)
            let clampedZoom = min(max(zoomFactor, minZoomFactor), maxZoomFactor)

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clampedZoom
                device.unlockForConfiguration()

                self.currentState.zoomFactor = clampedZoom
                self.currentState.minZoomFactor = minZoomFactor
                self.currentState.maxZoomFactor = maxZoomFactor
                self.reportState()
            } catch {
                self.reportError(.configurationFailed)
            }
            #else
            self.currentState.zoomFactor = 1
            self.currentState.minZoomFactor = 1
            self.currentState.maxZoomFactor = 1
            self.reportState()
            #endif
        }
    }

    private func replaceInputIfNeeded(position: CameraPosition) {
        let desiredPosition = position.avPosition

        if currentInput?.device.position == desiredPosition {
            updateState(for: currentInput?.device, position: position)
            return
        }

        if let currentInput {
            session.removeInput(currentInput)
            self.currentInput = nil
        }

        guard let device = Self.videoDevice(for: desiredPosition) else {
            reportError(.cameraUnavailable(position))
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            reportError(.cannotAddInput)
            return
        }

        guard session.canAddInput(input) else {
            reportError(.cannotAddInput)
            return
        }

        session.addInput(input)
        currentInput = input
        currentPosition = position
        updateState(for: device, position: position)
    }

    private func applySessionPreset(_ preset: CameraSessionPreset) {
        let avPreset = preset.avPreset

        if session.canSetSessionPreset(avPreset) {
            session.sessionPreset = avPreset
        }
    }

    private func updateState(for device: AVCaptureDevice?, position: CameraPosition) {
        currentState.position = position
        currentState.isFlashAvailable = device?.isFlashAvailable ?? false
        currentState.isTorchAvailable = device?.hasTorch ?? false
        currentState.isSwitchCameraAvailable =
            Self.videoDevice(for: .front) != nil && Self.videoDevice(for: .back) != nil
        #if os(iOS)
        currentState.zoomFactor = device?.videoZoomFactor ?? 1
        currentState.minZoomFactor = max(device?.minAvailableVideoZoomFactor ?? 1, 1)
        currentState.maxZoomFactor = max(min(device?.maxAvailableVideoZoomFactor ?? 1, 10), 1)
        #else
        currentState.zoomFactor = 1
        currentState.minZoomFactor = 1
        currentState.maxZoomFactor = 1
        #endif
        reportState()
    }

    private func reportState() {
        onStateChange(currentState)
    }

    private func reportError(_ error: CameraError) {
        onError(error)
    }

    private func removeCaptureDelegate(_ delegate: PhotoCaptureDelegate) {
        sessionQueue.async {
            self.captureDelegates.removeAll { $0 === delegate }
        }
    }

    private static func videoDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let defaultDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        #if os(iOS)
        return defaultDevice
            ?? AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: position)
        #else
        return defaultDevice
        #endif
    }
}

@available(iOS 17, macOS 14, *)
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let onComplete: (Data?) -> Void

    init(onComplete: @escaping (Data?) -> Void) {
        self.onComplete = onComplete
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        onComplete(error == nil ? photo.fileDataRepresentation() : nil)
    }
}

@available(iOS 17, macOS 14, *)
private extension CameraPosition {
    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension CameraFlashMode {
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension CameraSessionPreset {
    var avPreset: AVCaptureSession.Preset {
        switch self {
        case .photo:
            return .photo
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }
}
