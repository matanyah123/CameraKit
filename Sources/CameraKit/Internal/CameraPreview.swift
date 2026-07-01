import AVFoundation
import SwiftUI

#if canImport(UIKit)
import UIKit

@available(iOS 17, macOS 14, *)
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let isTapGestureEnabled: Bool
    let isPinchToZoomEnabled: Bool
    let contentMode: CameraPreviewContentMode
    let onTap: (CGPoint) -> Void
    let onPinch: (CGFloat) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.onTap = onTap
        view.onPinch = onPinch
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        uiView.isTapGestureEnabled = isTapGestureEnabled
        uiView.isPinchToZoomEnabled = isPinchToZoomEnabled
        uiView.onTap = onTap
        uiView.onPinch = onPinch
        uiView.previewLayer.videoGravity = contentMode.videoGravity
    }
}

@available(iOS 17, macOS 14, *)
final class PreviewView: UIView {
    var onTap: (CGPoint) -> Void = { _ in }
    var onPinch: (CGFloat) -> Void = { _ in }

    var isTapGestureEnabled = true {
        didSet {
            tapGestureRecognizer.isEnabled = isTapGestureEnabled
        }
    }

    var isPinchToZoomEnabled = true {
        didSet {
            pinchGestureRecognizer.isEnabled = isPinchToZoomEnabled
        }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTap(_:))
    )

    private lazy var pinchGestureRecognizer = UIPinchGestureRecognizer(
        target: self,
        action: #selector(handlePinch(_:))
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(pinchGestureRecognizer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        onTap(devicePoint)
    }

    @objc
    private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        onPinch(recognizer.scale)
        recognizer.scale = 1
    }
}

@available(iOS 17, macOS 14, *)
private extension CameraPreviewContentMode {
    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fill:
            return .resizeAspectFill
        case .fit:
            return .resizeAspect
        }
    }
}
#else
@available(iOS 17, macOS 14, *)
struct CameraPreview: View {
    let session: AVCaptureSession
    let isTapGestureEnabled: Bool
    let isPinchToZoomEnabled: Bool
    let contentMode: CameraPreviewContentMode
    let onTap: (CGPoint) -> Void
    let onPinch: (CGFloat) -> Void

    var body: some View {
        Color.black
    }
}
#endif
