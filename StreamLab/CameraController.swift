import AVFoundation
import SwiftUI
import Combine

// AVCaptureSession mutations and blocking start/stop calls are confined to queue.
// Published UI state is delivered on main. The live feed is never recorded/uploaded.
final class CameraController: ObservableObject, @unchecked Sendable {
    enum Status: Equatable {
        case off, requesting, starting, live, denied, unavailable, interrupted, failed
        var title: String {
            switch self {
            case .off: return "Your camera. Your stage."
            case .requesting: return "Allow camera access"
            case .starting: return "Starting camera…"
            case .live: return "Camera live"
            case .denied: return "Camera access is off"
            case .unavailable: return "No camera available"
            case .interrupted: return "Camera interrupted"
            case .failed: return "Camera couldn't start"
            }
        }
        var detail: String {
            switch self {
            case .denied: return "Enable Camera for StreamLab in iPhone Settings."
            case .unavailable: return "Use a physical iPhone to try the front and rear cameras."
            case .interrupted: return "Another app or a system event interrupted the camera. Tap Retry when ready."
            case .failed: return "Try again or close other apps using the camera."
            default: return "Live on your screen. Nothing is recorded or broadcast."
            }
        }
    }
    let session = AVCaptureSession()
    @Published private(set) var status: Status = .off
    @Published private(set) var isFront = true
    @Published private(set) var device: AVCaptureDevice?
    @Published private(set) var scene: VisualScene?
    @Published private(set) var notice: String?
    @Published private(set) var cue: CameraCue?
    private let queue = DispatchQueue(label: "streamlab.camera", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let analyzer = CameraAnalyzer()
    private var analysisEnabled = true
    private var analysisGeneration: UInt64 = 0
    private var analysisOutputInstalled = false
    private var input: AVCaptureDeviceInput?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var requested = false
    private var observers: [NSObjectProtocol] = []

    init() {
        analyzer.onCue = { [weak self] event, generation in
            self?.queue.async { [weak self] in
                guard let self, self.requested, self.analysisEnabled, self.session.isRunning, generation == self.analysisGeneration else { return }
                DispatchQueue.main.async { self.cue = CameraCue(event: event) }
            }
        }
        analyzer.onScene = { [weak self] scene, generation in
            self?.queue.async { [weak self] in
                guard let self, self.requested, self.analysisEnabled, generation == self.analysisGeneration else { return }
                DispatchQueue.main.async { self.scene = scene }
            }
        }
        analyzer.onUnavailable = { [weak self] generation in
            self?.queue.async { [weak self] in
                guard let self, generation == self.analysisGeneration, self.analysisEnabled, self.requested else { return }
                DispatchQueue.main.async { self.notice = "Smile detection is unavailable. Movement cues can still work." }
            }
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: session, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in
                guard let self, self.requested else { return }
                self.configureAnalyzer(enabled: false, front: self.input?.device.position == .front)
                self.publish(.interrupted)
            }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: session, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in
                guard let self, self.requested else { return }
                self.configureAndStart()
            }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in
                guard let self, self.requested else { return }
                self.configureAnalyzer(enabled: false, front: self.input?.device.position == .front)
                self.publish(.failed)
            }
        })
    }
    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

    func setAnalysisEnabled(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.analysisEnabled = enabled
            self.configureAnalyzer(enabled: enabled && self.requested && self.session.isRunning, front: self.input?.device.position == .front)
            if !enabled { DispatchQueue.main.async { self.cue = nil; self.scene = nil } }
        }
    }
    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.requested = true
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: self.configureAndStart()
            case .notDetermined:
                self.publish(.requesting)
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    self?.queue.async { [weak self] in
                        guard let self, self.requested else { return }
                        if granted { self.configureAndStart() } else { self.publish(.denied) }
                    }
                }
            default: self.publish(.denied)
            }
        }
    }
    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.requested = false
            self.configureAnalyzer(enabled: false, front: self.input?.device.position == .front)
            DispatchQueue.main.async { self.cue = nil; self.scene = nil }
            if self.session.isRunning { self.session.stopRunning() }
            self.publish(.off)
        }
    }
    func flip() {
        queue.async { [weak self] in
            guard let self, self.requested, let old = self.input else { return }
            let target: AVCaptureDevice.Position = old.device.position == .front ? .back : .front
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: target),
                  let replacement = try? AVCaptureDeviceInput(device: device) else {
                DispatchQueue.main.async { self.notice = "The other camera is unavailable." }
                return
            }
            self.configureAnalyzer(enabled: false, front: target == .front)
            self.session.beginConfiguration()
            self.session.removeInput(old)
            let switched = self.session.canAddInput(replacement)
            if switched { self.session.addInput(replacement); self.input = replacement }
            else if self.session.canAddInput(old) { self.session.addInput(old) }
            else { self.input = nil }
            self.session.commitConfiguration()
            self.installRotationCoordinator()
            self.configureAnalyzer(enabled: self.analysisEnabled && self.input != nil && self.analysisOutputInstalled, front: self.input?.device.position == .front)
            let restored = self.input != nil
            if !restored { self.publish(.failed) }
            DispatchQueue.main.async {
                if switched { self.isFront = target == .front; self.device = replacement.device; self.notice = nil; self.scene = nil; self.cue = nil }
                else { self.notice = restored ? "Couldn't switch cameras. Your current camera is still selected." : "Camera connection lost. Tap Retry camera." }
            }
        }
    }
    private func configureAndStart() {
        guard requested else { return }
        if !session.isRunning { publish(.starting) }
        if input == nil {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                    ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let cameraInput = try? AVCaptureDeviceInput(device: device) else { publish(.unavailable); return }
            session.beginConfiguration()
            if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
            guard session.canAddInput(cameraInput) else { session.commitConfiguration(); publish(.failed); return }
            session.addInput(cameraInput); input = cameraInput
            if !analysisOutputInstalled && session.canAddOutput(videoOutput) {
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                videoOutput.setSampleBufferDelegate(analyzer, queue: analyzer.queue)
                session.addOutput(videoOutput)
                analysisOutputInstalled = true
            }
            session.commitConfiguration()
            if !analysisOutputInstalled {
                DispatchQueue.main.async { self.notice = "Camera reactions are unavailable. Manual Studio moments still work." }
            }
            DispatchQueue.main.async { self.isFront = device.position == .front; self.device = device }
        }
        installRotationCoordinator()
        configureAnalyzer(enabled: analysisEnabled && analysisOutputInstalled, front: input?.device.position == .front)
        if !session.isRunning { session.startRunning() }
        publish(session.isRunning ? .live : .failed)
    }
    private func configureAnalyzer(enabled: Bool, front: Bool) {
        analysisGeneration &+= 1
        analyzer.configure(enabled: enabled, front: front, generation: analysisGeneration)
    }
    private func installRotationCoordinator() {
        guard let device = input?.device else { return }
        if rotationCoordinator?.device?.uniqueID != device.uniqueID {
            rotationObservation?.invalidate()
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
            rotationCoordinator = coordinator
            rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: [.new]) { [weak self] coordinator, _ in
                let angle = coordinator.videoRotationAngleForHorizonLevelCapture
                let deviceID = coordinator.device?.uniqueID
                self?.queue.async { [weak self] in
                    guard let self, self.input?.device.uniqueID == deviceID else { return }
                    self.configureAnalysisConnection(angle: angle)
                }
            }
        }
        configureAnalysisConnection(angle: rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 0)
    }
    private func configureAnalysisConnection(angle: CGFloat) {
        guard let connection = videoOutput.connection(with: .video) else { return }
        if connection.isVideoRotationAngleSupported(angle), connection.videoRotationAngle != angle { connection.videoRotationAngle = angle }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
    }
    private func publish(_ value: Status) {
        DispatchQueue.main.async { [weak self] in self?.status = value }
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var observation: NSKeyValueObservation?
    private var deviceID: String?
    private var mirror = true
    func configure(device: AVCaptureDevice?, mirror: Bool) {
        self.mirror = mirror
        if deviceID != device?.uniqueID {
            observation?.invalidate(); observation = nil; rotationCoordinator = nil
            deviceID = device?.uniqueID
            if let device {
                let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
                rotationCoordinator = coordinator
                // Apple delivers preview-angle changes on the main queue.
                observation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] _, _ in
                    self?.updateConnection()
                }
            }
        }
        updateConnection()
    }
    override func layoutSubviews() { super.layoutSubviews(); updateConnection() }
    override func didMoveToWindow() { super.didMoveToWindow(); updateConnection() }
    private func updateConnection() {
        guard let connection = previewLayer.connection, let coordinator = rotationCoordinator else { return }
        let angle = coordinator.videoRotationAngleForHorizonLevelPreview
        if connection.isVideoRotationAngleSupported(angle), connection.videoRotationAngle != angle { connection.videoRotationAngle = angle }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirrored != mirror { connection.isVideoMirrored = mirror }
        }
    }
}
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let device: AVCaptureDevice?
    let mirror: Bool
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        view.configure(device: device, mirror: mirror)
        return view
    }
    func updateUIView(_ uiView: CameraPreviewView, context: Context) { uiView.configure(device: device, mirror: mirror) }
}
