import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 17, macOS 14, *)
@MainActor
@Observable
public final class CameraOutput {
    public private(set) var photos: [CameraPhoto] = []
    public internal(set) var authorizationState: CameraAuthorizationState = .notDetermined
    public internal(set) var status: CameraStatus = .idle
    public internal(set) var lastError: CameraError?

    public var lastPhoto: CameraPhoto? {
        photos.last
    }

    public init() {}

    func appendPhotoData(_ data: Data) {
        let photo = CameraPhoto(imageData: data)
        photos.append(photo)
        status = .photoCaptured(photo)
        lastError = nil
    }

    public func removeAllPhotos() {
        photos.removeAll()
    }

    func setAuthorizationState(_ state: CameraAuthorizationState) {
        authorizationState = state
    }

    func setStatus(_ status: CameraStatus) {
        self.status = status
    }

    func setError(_ error: CameraError?) {
        lastError = error
        if let error {
            status = .failed(error)
        }
    }
}

public struct CameraPhoto: Identifiable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let imageData: Data
    public let capturedAt: Date

    public init(
        id: UUID = UUID(),
        imageData: Data,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.capturedAt = capturedAt
    }

    #if canImport(UIKit)
    public var uiImage: UIImage? {
        UIImage(data: imageData)
    }
    #endif
}

@available(iOS 17, macOS 14, *)
public enum CameraAuthorizationState: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
}

@available(iOS 17, macOS 14, *)
public enum CameraStatus: Sendable, Equatable {
    case idle
    case requestingPermission
    case ready
    case capturing
    case photoCaptured(CameraPhoto)
    case failed(CameraError)
}

@available(iOS 17, macOS 14, *)
public enum CameraError: Error, Sendable, Equatable, LocalizedError {
    case cameraUnavailable(CameraPosition)
    case cannotAddInput
    case cannotAddOutput
    case configurationFailed
    case captureFailed
    case focusFailed
    case torchUnavailable

    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable(let position):
            return "No \(position == .front ? "front" : "back") camera is available on this device."
        case .cannotAddInput:
            return "The camera input could not be added to the session."
        case .cannotAddOutput:
            return "The photo output could not be added to the session."
        case .configurationFailed:
            return "The camera session could not be configured."
        case .captureFailed:
            return "The photo could not be captured."
        case .focusFailed:
            return "The camera could not focus at that point."
        case .torchUnavailable:
            return "Torch is unavailable for the active camera."
        }
    }
}
