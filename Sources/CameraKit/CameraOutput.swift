import Foundation
import Observation

@Observable
public final class CameraOutput {
    public private(set) var photos: [CameraPhoto] = []

    public var lastPhoto: CameraPhoto? {
        photos.last
    }

    public init() {}

    func appendPhotoData(_ data: Data) {
        photos.append(CameraPhoto(imageData: data))
    }
}

public struct CameraPhoto: Identifiable, Sendable, Equatable {
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
}
