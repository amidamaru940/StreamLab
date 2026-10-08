import Foundation

/// Who is addressed. The host is not a participant.
enum Addressee: Equatable {
    case host
    case participant(Int)
}

enum MessageSource: String, Codable, CaseIterable {
    case topicOpener, topicAnswer, topicFollowUp, sideReaction
    case hostReply, viewerToHost, acknowledgement
    case eventReaction, presence, gift, giftReaction, thanks, ambientAI
}

enum DropReason: String, CaseIterable {
    case expired, staleContext, duplicate, speakerLeft, queueFull
}

/// A message that has an author, a cause and a time window, but has not been shown yet (E3).
/// Text readiness and publication are separate: a writer may improve `text` until `due`.
struct PlannedMessage: Identifiable {
    let id = UUID()
    let participant: Int
    var text: String
    let source: MessageSource
    let addressee: Addressee?
    /// The visible message this one answers, if any. It must already be on screen before delivery.
    let replyToMessage: UUID?
    let causeTime: Double
    let earliest: Double
    var due: Double
    let expires: Double
    /// Event-bound reactions die when the moment they react to is replaced.
    let eventEpoch: Int?
    let topicID: String?
    /// What the writer should respond to, for the on-device model.
    let prompt: String
    var writerEligible: Bool
    var writerRequested = false
    var writtenByModel = false
}

/// Human-like time to notice, read, think and type (A6). Hypotheses for tuning, not statistics.
enum ReactionTiming {
    enum Kind { case quick, reply, comment, opener }
    static func delay(voice: Voice, kind: Kind, readText: String, replyLength: Int, using random: inout StreamRandom) -> Double {
        let words = Double(readText.split(separator: " ").count)
        let notice = voice.noticeLag * random.logNormal(sigma: 0.5)
        let read = words / voice.readingWordsPerSecond
        let think: Double
        switch kind {
        case .quick: think = 0.2 + random.unit() * 0.6
        case .reply: think = 0.8 + random.unit() * 2.5
        case .comment: think = 0.5 + random.unit() * 2
        case .opener: think = 0
        }
        let type = Double(replyLength) / voice.typingCharactersPerSecond * random.logNormal(sigma: 0.25)
        let floor: Double = kind == .quick ? 1.3 : kind == .opener ? 0.3 : 2.6
        // Some people only get back to chat a while later.
        let distracted = kind != .quick && random.unit() < 0.18 ? 5 + random.unit() * 14 : 0
        return max(floor, (kind == .quick ? notice * 0.6 : notice) + (kind == .quick ? read * 0.4 : read) + think + type + distracted)
    }
}

/// Lightweight understanding of what the host typed. Text is data, never an instruction.
struct HostIntent: Equatable {
    enum Kind: Equatable {
        case greeting, howAreYou, thanks, bye
        case yesNoQuestion, openQuestion
        case choice(String, String)
        case statement
        case nonEnglish
    }
    let kind: Kind
    let mentions: [String]
    let keywords: Set<String>
    let event: StreamEvent?

    var isQuestion: Bool {
        switch kind {
        case .yesNoQuestion, .openQuestion, .choice, .howAreYou: return true
        default: return false
        }
    }

    static func parse(_ raw: String) -> HostIntent {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased().replacingOccurrences(of: "’", with: "'")
        let words = lower.split { !$0.isLetter && $0 != "'" && $0 != "@" && $0 != "_" && !$0.isNumber }.map(String.init)
        let mentions = text.split(separator: " ").filter { $0.hasPrefix("@") && $0.count > 1 }
            .map { String($0.dropFirst()).trimmingCharacters(in: .punctuationCharacters).lowercased() }
        let event = detectEvent(lower: lower, words: words)
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        let latin = letters.filter { $0.isASCII }.count
        if letters.count >= 3 && Double(latin) / Double(letters.count) < 0.6 {
            return HostIntent(kind: .nonEnglish, mentions: mentions, keywords: [], event: event)
        }
        let plain = words.filter { !$0.hasPrefix("@") }
        let keywords = Set(plain)
        let first = plain.first ?? ""
        let has = { (list: [String]) in list.contains { keywords.contains($0) } }
        let question = text.contains("?")
        let kind: Kind
        if has(["hi", "hello", "hey", "hiya", "yo", "evening", "morning", "sup"]) && plain.count <= 5 && !question { kind = .greeting }
        else if lower.contains("how are you") || lower.contains("how's everyone") || lower.contains("how is everyone") || lower.contains("how are we") || lower.contains("how's your") || lower.contains("how was your") { kind = .howAreYou }
        else if has(["thanks", "thank", "ty", "thx"]) { kind = .thanks }
        else if has(["bye", "goodnight", "night", "ending", "signing"]) && !question { kind = .bye }
        else if let options = choice(in: lower) { kind = .choice(options.0, options.1) }
        else if question || ["what", "why", "how", "who", "where", "which", "when"].contains(first) {
            let yesNoStarts: Set<String> = ["do", "does", "did", "is", "are", "was", "were", "can", "could", "should", "would", "will", "have", "has", "anyone", "any", "shall", "am", "you"]
            kind = yesNoStarts.contains(first) ? .yesNoQuestion : .openQuestion
        } else { kind = .statement }
        return HostIntent(kind: kind, mentions: mentions, keywords: keywords, event: event)
    }

    /// "Tea or coffee?" → ("tea", "coffee"). Only short, clean options are used.
    static func choice(in lower: String) -> (String, String)? {
        guard let range = lower.range(of: " or ") else { return nil }
        let filler: Set<String> = ["should", "i", "we", "do", "you", "prefer", "like", "want", "would", "rather", "play", "go", "with", "for", "the", "a", "an", "chat", "guys", "so", "ok", "okay", "which", "is", "it", "better", "more", "what", "pick", "team"]
        let before = lower[..<range.lowerBound].split { !$0.isLetter && $0 != "'" && $0 != "-" }.map(String.init)
        var leftWords: [String] = []
        for word in before.reversed() { if filler.contains(word) || leftWords.count == 2 { break }; leftWords.insert(word, at: 0) }
        let after = lower[range.upperBound...].prefix { $0 != "?" && $0 != "." && $0 != "," && $0 != "!" }
        let rightWords = Array(after.split { !$0.isLetter && $0 != "'" && $0 != "-" }.map(String.init).filter { !["the", "a", "an"].contains($0) }.prefix(2))
        guard !leftWords.isEmpty, !rightWords.isEmpty, rightWords.count <= 2 else { return nil }
        let left = leftWords.joined(separator: " "), right = rightWords.joined(separator: " ")
        guard left != right, left.count <= 20, right.count <= 20, !["not", "no"].contains(right) else { return nil }
        return (left, right)
    }

    private static func detectEvent(lower: String, words: [String]) -> StreamEvent? {
        let negative = lower.contains("won't") || lower.contains("didn't") || ["not", "never", "haven't", "no", "не"].contains { words.contains($0) }
        if !negative && (words.contains("won") || words.contains("победа")) { return .win }
        if words.contains("haha") || words.contains("hahaha") || words.contains("хаха") || words.contains("lmao") { return .laugh }
        if words.contains("brb") || words.contains("перерыв") { return .breakTime }
        return nil
    }
}

/// Structural, anonymised measurements (F1/E1). No raw frames, audio or host text.
struct EngineMetrics {
    private(set) var delivered: [MessageSource: Int] = [:]
    private(set) var dropped: [DropReason: Int] = [:]
    private(set) var hostReplyDelays: [Double] = []
    private(set) var reactionDelays: [Double] = []
    private(set) var lateness: [Double] = []
    private(set) var modelWritten = 0
    private(set) var modelDelivered = 0
    private(set) var modelDiscarded = 0
    private(set) var sameUpdateReplies = 0

    mutating func record(_ message: PlannedMessage, at time: Double) {
        delivered[message.source, default: 0] += 1
        let delay = time - message.causeTime
        if message.source == .hostReply { Self.keep(&hostReplyDelays, delay) }
        if message.source == .eventReaction { Self.keep(&reactionDelays, delay) }
        Self.keep(&lateness, time - message.due)
        if message.writtenByModel { modelDelivered += 1 }
        if (message.source == .hostReply || message.source == .eventReaction) && delay < 1 { sameUpdateReplies += 1 }
    }
    mutating func drop(_ message: PlannedMessage, _ reason: DropReason) {
        dropped[reason, default: 0] += 1
        if message.writtenByModel { modelDiscarded += 1 }
    }
    mutating func modelAccepted(_ count: Int) { modelWritten += count }
    var totalDelivered: Int { delivered.values.reduce(0, +) }
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted(); return sorted[sorted.count / 2]
    }
    static func percentile(_ values: [Double], _ p: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted(); return sorted[min(sorted.count - 1, Int(Double(sorted.count) * p))]
    }
    private static func keep(_ list: inout [Double], _ value: Double) {
        list.append(value); if list.count > 400 { list.removeFirst(list.count - 400) }
    }
}

// MARK: - On-device writer contract (E2/E3)

/// One line the app already decided to post. The model only words it.
struct WritingSlot: Identifiable, Equatable {
    enum Kind: String { case replyToHost, answerViewer, eventReaction, ambient }
    let id: UUID
    let kind: Kind
    let voice: String
    let about: String
    let maxLength: Int
}

struct WritingRequest: Equatable {
    let id = UUID()
    let category: String
    let streamTitle: String
    let visualHint: String
    let recentChat: [String]
    let slots: [WritingSlot]
    /// Fresh neutral lines for later use; authorship is assigned by the app when they are posted.
    let ambientCount: Int
}

struct WritingResult {
    var slotTexts: [UUID: String]
    var ambient: [String]

    /// Reads the model's structured JSON. Unknown keys are ignored; oversized or malformed output is rejected.
    static func parse(_ json: String, request: WritingRequest) -> WritingResult? {
        guard json.utf8.count <= 12000, let start = json.firstIndex(of: "{"), let end = json.lastIndex(of: "}"), start <= end,
              let object = try? JSONSerialization.jsonObject(with: Data(json[start...end].utf8)) as? [String: Any] else { return nil }
        var texts: [UUID: String] = [:]
        for (index, slot) in request.slots.enumerated() {
            if let value = object["line\(index + 1)"] as? String { texts[slot.id] = value }
        }
        let ambient = (object["ambient"] as? [Any])?.compactMap { $0 as? String } ?? []
        return WritingResult(slotTexts: texts, ambient: ambient)
    }
}
