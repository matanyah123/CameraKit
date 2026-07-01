import Foundation
import Testing
@testable import CameraKit

@MainActor
struct CameraKitTests {
    @Test
    func outputTracksCapturedPhotos() {
        let output = CameraOutput()
        let payload = Data([0xFF, 0xD8, 0xFF, 0xD9])

        output.appendPhotoData(payload)

        #expect(output.photos.count == 1)
        #expect(output.lastPhoto?.imageData == payload)

        output.removeAllPhotos()

        #expect(output.photos.isEmpty)
        #expect(output.lastPhoto == nil)
    }

    @Test
    func cameraErrorDescriptionsAreHelpful() {
        #expect(CameraError.captureFailed.errorDescription == "The photo could not be captured.")
        #expect(CameraError.cameraUnavailable(.front).errorDescription == "No front camera is available on this device.")
    }
}
