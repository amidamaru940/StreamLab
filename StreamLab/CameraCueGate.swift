import Foundation

struct CameraObservation {
    let faceVisible: Bool
    let smiling: Bool
    /// Mean difference between sampled luminance pixels, normalized to 0...1.
    let motion: Double
}
struct CameraCue: Identifiable, Equatable {
    let id = UUID()
    let event: StreamEvent
}

// Pure, testable temporal filtering. Signals describe visible cues, not emotions.
struct CameraCueGate {
    private var firstSample: Double?
    private var previousTime: Double?
    private var stableFace: Bool?
    private var faceCandidate: Bool?
    private var faceSince: Double = 0
    private var smileSince: Double?
    private var neutralSince: Double?
    private var smileLatched = false
    private var motionSince: Double?
    private var quietSince: Double?
    private var motionLatched = false
    private var emitted: [StreamEvent: Double] = [:]

    mutating func reset() { self = CameraCueGate() }
    mutating func observe(_ sample: CameraObservation, at time: Double, frontCamera: Bool) -> StreamEvent? {
        guard time.isFinite else { return nil }
        if let previousTime, time < previousTime || time - previousTime > 2 { reset() }
        previousTime = time
        if firstSample == nil { firstSample = time }
        if faceCandidate != sample.faceVisible {
            faceCandidate = sample.faceVisible; faceSince = time
        }
        // Warm-up protects against a camera switch or initial exposure change.
        guard time - (firstSample ?? time) >= 3 else { return nil }
        var candidate: StreamEvent?
        if stableFace == nil { stableFace = sample.faceVisible }
        if frontCamera, let stableFace, stableFace != sample.faceVisible {
            let duration: Double = sample.faceVisible ? 1.5 : 5
            if time - faceSince >= duration {
                self.stableFace = sample.faceVisible
                candidate = sample.faceVisible ? .faceBack : .faceAway
            }
        }
        // A smile seen by the rear camera is someone else's; only the selfie camera shows the host.
        if frontCamera && sample.faceVisible && sample.smiling {
            neutralSince = nil
            if smileSince == nil { smileSince = time }
            if !smileLatched && time - (smileSince ?? time) >= 1.5 {
                smileLatched = true
                if candidate == nil { candidate = .smile }
            }
        } else {
            smileSince = nil
            if neutralSince == nil { neutralSince = time }
            if time - (neutralSince ?? time) >= 2 { smileLatched = false }
        }
        if sample.motion.isFinite && sample.motion > 0.12 {
            quietSince = nil
            if motionSince == nil { motionSince = time }
            if !motionLatched && time - (motionSince ?? time) >= 1 {
                motionLatched = true
                if candidate == nil { candidate = .movement }
            }
        } else {
            motionSince = nil
            if quietSince == nil { quietSince = time }
            if time - (quietSince ?? time) >= 3 { motionLatched = false }
        }
        guard let candidate else { return nil }
        let cooldown: Double = candidate == .smile ? 60 : candidate == .movement ? 70 : 15
        guard time - (emitted[candidate] ?? -1000) >= cooldown else { return nil }
        emitted[candidate] = time
        return candidate
    }
}

/// Only broad visual hints; no identity, mood, location or speech inference.
enum VisualScene: String, Codable, CaseIterable {
    case pet, food, outdoors, music
    var event: StreamEvent {
        switch self { case .pet: return .pet; case .food: return .food; case .outdoors: return .outdoors; case .music: return .music }
    }
    var scenario: Scenario {
        switch self { case .pet: return .cozy; case .food: return .kitchen; case .outdoors: return .outdoors; case .music: return .music }
    }
    var fact: String { event.fact }
    static func classify(identifier: String, confidence: Float) -> VisualScene? {
        guard confidence >= 0.72 else { return nil }
        let words = Set(identifier.lowercased().split { !$0.isLetter }.map(String.init))
        if !words.isDisjoint(with: ["cat", "dog", "kitten", "puppy"]) { return .pet }
        if !words.isDisjoint(with: ["food", "meal", "pizza", "sandwich", "bread", "fruit", "vegetable", "dessert"]) { return .food }
        if !words.isDisjoint(with: ["guitar", "piano", "violin", "saxophone", "instrument"]) { return .music }
        if !words.isDisjoint(with: ["outdoor", "outdoors", "landscape", "forest", "beach", "park", "mountain"]) { return .outdoors }
        return nil
    }
}
struct SceneCueGate {
    private var candidate: VisualScene?
    private var count = 0
    private var misses = 0
    private var lastTime: Double?
    private(set) var stable: VisualScene?
    mutating func reset() { self = SceneCueGate() }
    mutating func observe(_ value: VisualScene?, at time: Double) -> VisualScene? {
        guard time.isFinite else { return stable }
        if let lastTime, time < lastTime || time - lastTime > 10 { reset() }
        lastTime = time
        if let value {
            misses = 0
            if candidate == value { count += 1 } else { candidate = value; count = 1 }
            if count >= 3 { stable = value }
        } else {
            candidate = nil; count = 0; misses += 1
            if misses >= 2 { stable = nil }
        }
        return stable
    }
}
