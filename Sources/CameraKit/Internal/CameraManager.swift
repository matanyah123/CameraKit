import AVFoundation
import CoreGraphics
import Foundation

final class CameraManager: NSObject {
    let session = AVCaptureSession()

    var onPhotoData: (Data) -> Void = { _ in }

    private let sessionQueue = DispatchQueue(label: "CameraKit.CameraManager")
    private let photoOutput = AVCapturePhotoOutput()

    private var currentInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private var captureDelegates: [PhotoCaptureDelegate] = []

    func configureIfNeeded(position: CameraPosition) {
        sessionQueue.async {
            if self.isConfigured {
                self.replaceInputIfNeeded(position: position)
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.replaceInputIfNeeded(position: position)
            self.session.commitConfiguration()
            self.isConfigured = true
        }
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
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
                guard let self, let data else { return }
                self.onPhotoData(data)
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
            } catch {}
        }
    }

    private func replaceInputIfNeeded(position: CameraPosition) {
        let desiredPosition = position.avPosition

        if currentInput?.device.position == desiredPosition {
            return
        }

        if let currentInput {
            session.removeInput(currentInput)
            self.currentInput = nil
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: desiredPosition),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)
        currentInput = input
    }

    private func removeCaptureDelegate(_ delegate: PhotoCaptureDelegate) {
        sessionQueue.async {
            self.captureDelegates.removeAll { $0 === delegate }
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
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
