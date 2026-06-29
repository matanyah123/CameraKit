import SwiftUI

public extension View {
    func cameraControls<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        environment(\.cameraControlsContent, AnyView(content()))
    }
}

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
            }
        }
        .buttonStyle(.plain)
        .disabled(!context.isCaptureAvailable)
        .opacity(context.isCaptureAvailable ? 1.0 : 0.55)
    }
}
