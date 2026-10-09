import AVFoundation
import CoreImage
import Vision

/// Samples at most two frames per second. No frame is persisted or transmitted.
/// Core Image's smile flag is a fallible visual cue, not an emotional assessment.
final class CameraAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "streamlab.camera.analysis", qos: .utility)
    var onCue: ((StreamEvent, UInt64) -> Void)?
    var onScene: ((VisualScene?, UInt64) -> Void)?
    var onUnavailable: ((UInt64) -> Void)?
    private var enabled = false
    private var generation: UInt64 = 0
    private var front = true
    private var lastSample = -Double.infinity
    private var previousPixels: [Float]?
    private var gate = CameraCueGate()
    private var sceneGate = SceneCueGate()
    private var lastClassification = -Double.infinity
    private let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    func configure(enabled: Bool, front: Bool, generation: UInt64) {
        queue.async { [weak self] in
            guard let self else { return }
            self.enabled = enabled; self.front = front; self.generation = generation
            self.lastSample = -.infinity; self.previousPixels = nil; self.gate.reset(); self.sceneGate.reset(); self.lastClassification = -.infinity
            if enabled && self.detector == nil { self.onUnavailable?(generation) }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard enabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSample >= 0.5, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastSample = now
        autoreleasepool {
            if now - lastClassification >= 3 && !ProcessInfo.processInfo.isLowPowerModeEnabled && ProcessInfo.processInfo.thermalState != .serious && ProcessInfo.processInfo.thermalState != .critical {
                lastClassification = now
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
                if (try? handler.perform([request])) != nil {
                    let scene = request.results?.prefix(5).compactMap { VisualScene.classify(identifier: $0.identifier, confidence: $0.confidence) }.first
                    onScene?(sceneGate.observe(scene, at: now), generation)
                } else { onScene?(sceneGate.observe(nil, at: now), generation) }
            }
            let image = CIImage(cvPixelBuffer: buffer)
            let scale = min(1, 480 / max(image.extent.width, image.extent.height))
            let small = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            // The video output connection rotates buffers upright; the preview mirrors separately.
            let features = (detector?.features(in: small, options: [CIDetectorSmile: true, CIDetectorImageOrientation: 1]) as? [CIFaceFeature]) ?? []
            let face = features.filter { $0.bounds.width >= small.extent.width * 0.10 }.max { $0.bounds.width < $1.bounds.width }
            let pixels = sampleLuma(buffer)
            var motion: Double = 0
            if let previousPixels, let pixels, previousPixels.count == pixels.count {
                // Remove global exposure change so switching a light does not look like motion.
                let exposure = zip(pixels, previousPixels).map { $0 - $1 }.reduce(0, +) / Float(pixels.count)
                motion = Double(zip(pixels, previousPixels).map { abs(($0 - $1) - exposure) }.reduce(0, +) / Float(pixels.count))
            }
            previousPixels = pixels
            let sample = CameraObservation(faceVisible: face != nil, smiling: face?.hasSmile == true, motion: motion)
            if let event = gate.observe(sample, at: now, frontCamera: front) { onCue?(event, generation) }
        }
    }
    private func sampleLuma(_ buffer: CVPixelBuffer) -> [Float]? {
        guard CVPixelBufferGetPlaneCount(buffer) > 0 else { return nil }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else { return nil }
        let width = CVPixelBufferGetWidthOfPlane(buffer, 0), height = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        var result: [Float] = []
        result.reserveCapacity(24 * 32)
        for row in 0..<32 {
            for column in 0..<24 {
                let x = min(width - 1, (2 * column + 1) * width / 48)
                let y = min(height - 1, (2 * row + 1) * height / 64)
                result.append(Float(bytes[y * stride + x]) / 255)
            }
        }
        return result
    }
}
