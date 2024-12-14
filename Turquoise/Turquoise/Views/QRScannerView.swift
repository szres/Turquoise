import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    let onScanned: (String, String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerViewControllerDelegate {
        let parent: QRScannerView
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        func qrScannerViewController(_ controller: QRScannerViewController, didScanCode code: String) {
            print("📱 Scanned code: \(code)")
            
            if let url = URL(string: code),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               components.path.hasPrefix("/endpoint/"),
               let nameParam = components.queryItems?.first(where: { $0.name == "name" })?.value,
               let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value,
               let decodedName = nameParam.removingPercentEncoding {
                print("✅ Valid endpoint URL detected")
                print("📝 Name: \(decodedName)")
                print("🔗 URL: \(urlParam)")
                
                // 先停止扫描
                controller.stopScanning()
                
                // 在主线程执行回调和关闭操作
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.onScanned(decodedName, urlParam)
                    self.parent.isPresented = false
                }
            } else {
                print("❌ Invalid QR code format")
            }
        }
    }
}

protocol QRScannerViewControllerDelegate: AnyObject {
    func qrScannerViewController(_ controller: QRScannerViewController, didScanCode code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerViewControllerDelegate?
    private var captureSession: AVCaptureSession?
    private var isScanning = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.captureSession = captureSession
        startScanning()
    }
    
    func startScanning() {
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        isScanning = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScanning else { return }
        
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            delegate?.qrScannerViewController(self, didScanCode: stringValue)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
}