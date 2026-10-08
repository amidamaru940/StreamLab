import Foundation

enum StreamEvent: String, CaseIterable, Codable, Identifiable {
    case laugh = "Laugh", win = "Win", fail = "Fail", debate = "Debate", breakTime = "BRB", returnLive = "Back"
    case smile = "Smile detected", faceAway = "Face out of frame", faceBack = "Face in frame", movement = "Camera movement"
    case pet = "Pet in view", food = "Food in view", outdoors = "Outdoor view", music = "Instrument in view"
    static var manualCases: [StreamEvent] { [.laugh, .win, .fail, .debate, .breakTime, .returnLive] }
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .laugh, .smile: return "face.smiling"
        case .win: return "trophy"
        case .fail: return "arrow.counterclockwise"
        case .debate: return "bubble.left.and.bubble.right"
        case .breakTime: return "cup.and.saucer"
        case .returnLive: return "play.circle"
        case .faceAway: return "person.crop.rectangle.badge.xmark"
        case .faceBack: return "person.crop.rectangle"
        case .movement: return "camera.viewfinder"
        case .pet: return "pawprint"
        case .food: return "fork.knife"
        case .outdoors: return "leaf"
        case .music: return "music.note"
        }
    }
    var fact: String {
        switch self {
        case .smile: return "A sustained smile was detected; its cause is unknown."
        case .faceAway: return "A face is no longer detected in the front camera. The person may simply have turned away."
        case .faceBack: return "A face returned to the front camera frame."
        case .movement: return "The picture moved. We do not know what moved or where the person is going."
        case .pet: return "The image classifier repeatedly detected a cat or dog; the species and name are not confirmed."
        case .food: return "Food is likely visible. No dish, ingredients, taste or action is confirmed."
        case .outdoors: return "An outdoor scene is likely visible. The place and weather are unknown."
        case .music: return "A musical instrument is likely visible. No audio is available."
        default: return "The host explicitly marked this moment as: " + rawValue
        }
    }
}
enum Personality: String, CaseIterable, Codable, Identifiable {
    case supporter = "Supportive", joker = "Playful", analyst = "Thoughtful", skeptic = "Skeptical"
    var id: String { rawValue }
}
enum Scenario: String, CaseIterable, Codable, Identifiable {
    case automatic = "Auto · follow camera", cozy = "Just chatting", gaming = "Late night gaming", challenge = "One more attempt"
    case kitchen = "Cooking & food", outdoors = "IRL & outdoors", music = "Music & practice", study = "Focus & study"
    var id: String { rawValue }
    var category: String {
        switch self {
        case .automatic, .cozy: return "Just Chatting"
        case .gaming: return "Gaming"
        case .challenge: return "Challenges"
        case .kitchen: return "Food & Drink"
        case .outdoors: return "IRL"
        case .music: return "Music"
        case .study: return "Study With Me"
        }
    }
    var symbol: String {
        switch self {
        case .automatic: return "sparkles"
        case .cozy: return "bubble.left.and.bubble.right"
        case .gaming: return "gamecontroller"
        case .challenge: return "flag.checkered"
        case .kitchen: return "fork.knife"
        case .outdoors: return "leaf"
        case .music: return "music.note"
        case .study: return "book"
        }
    }
    var subtitle: String {
        switch self {
        case .automatic: return "Let the room follow your camera."
        case .cozy: return "Conversation, small stories, late company."
        case .gaming: return "A room for games and reactions."
        case .challenge: return "Trying, learning and trying again."
        case .kitchen: return "Cooking questions and food talk."
        case .outdoors: return "Take chat along for the walk."
        case .music: return "Practice, instruments and music talk."
        case .study: return "Quiet company while you focus."
        }
    }
    var timeline: [StreamEvent] {
        switch self {
        case .gaming, .challenge: return [.fail, .laugh, .win, .debate]
        default: return [.laugh, .debate, .breakTime, .returnLive]
        }
    }
}
struct Settings: Codable {
    var schemaVersion = 6
    var messagesPerMinute: Double = 24
    var donationsPerMinute: Double = 0.85
    var minAmount: Double = 10
    var maxAmount: Double = 900
    var scenario: Scenario = .automatic
    var autoplay = false
    var cameraReactions = true
    var localWriting = true
    var pauseModelInLowPower = true
    var tipDuration: Double = 7
    var channelName = "nightshift"
    var streamTitle = "Just one more minute"
    init() {}
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, messagesPerMinute, donationsPerMinute, minAmount, maxAmount, scenario, autoplay, cameraReactions, localWriting, pauseModelInLowPower, tipDuration, channelName, streamTitle
    }
    init(from decoder: Decoder) throws {
        self.init()
        let v = try decoder.container(keyedBy: CodingKeys.self)
        let oldVersion = (try? v.decode(Int.self, forKey: .schemaVersion)) ?? 4
        messagesPerMinute = (try? v.decode(Double.self, forKey: .messagesPerMinute)) ?? messagesPerMinute
        if let saved = try? v.decode(Double.self, forKey: .donationsPerMinute) { donationsPerMinute = oldVersion < 5 ? saved * 0.85 : saved }
        minAmount = (try? v.decode(Double.self, forKey: .minAmount)) ?? minAmount
        maxAmount = (try? v.decode(Double.self, forKey: .maxAmount)) ?? maxAmount
        // v5 defaults old sessions to automatic mixed chat, as requested.
        if oldVersion >= 5 { scenario = (try? v.decode(Scenario.self, forKey: .scenario)) ?? scenario }
        autoplay = oldVersion >= 5 ? ((try? v.decode(Bool.self, forKey: .autoplay)) ?? false) : false
        cameraReactions = (try? v.decode(Bool.self, forKey: .cameraReactions)) ?? cameraReactions
        localWriting = (try? v.decode(Bool.self, forKey: .localWriting)) ?? localWriting
        pauseModelInLowPower = (try? v.decode(Bool.self, forKey: .pauseModelInLowPower)) ?? pauseModelInLowPower
        tipDuration = (try? v.decode(Double.self, forKey: .tipDuration)) ?? tipDuration
        channelName = (try? v.decode(String.self, forKey: .channelName)) ?? channelName
        streamTitle = (try? v.decode(String.self, forKey: .streamTitle)) ?? streamTitle
        normalize()
    }
    mutating func normalize() {
        schemaVersion = 6
        channelName = String(channelName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        streamTitle = String(streamTitle.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        if channelName.isEmpty { channelName = "nightshift" }
        if streamTitle.isEmpty { streamTitle = "Just one more minute" }
        messagesPerMinute = min(90, max(2, messagesPerMinute.isFinite ? messagesPerMinute : 24))
        donationsPerMinute = min(12, max(0, donationsPerMinute.isFinite ? donationsPerMinute : 0.85))
        minAmount = min(900, max(10, minAmount.isFinite ? minAmount : 10))
        maxAmount = min(900, max(minAmount, maxAmount.isFinite ? maxAmount : 900))
        tipDuration = min(12, max(5, tipDuration.isFinite ? tipDuration : 7))
    }
}
struct StreamRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func index(_ count: Int) -> Int { Int(next() % UInt64(max(1, count))) }
    mutating func unit() -> Double { Double(next() >> 11) / 9007199254740992 }
    mutating func gaussian() -> Double {
        let u = max(1e-12, unit()), v = unit()
        return (-2 * log(u)).squareRoot() * cos(2 * Double.pi * v)
    }
    /// Multiplicative noise with median 1.
    mutating func logNormal(sigma: Double) -> Double { exp(gaussian() * sigma) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ items: [T]) -> T? { items.isEmpty ? nil : items[index(items.count)] }
    /// Small counts with a realistic long tail: 0, 1, 2 common; 5+ rare.
    mutating func count(weights: [Double]) -> Int {
        var roll = unit() * weights.reduce(0, +)
        for (i, w) in weights.enumerated() { roll -= w; if roll < 0 { return i } }
        return weights.count - 1
    }
}
struct ChatMessage: Identifiable {
    let id: UUID
    let participantID: Int?
    let name: String
    let avatar: String
    let color: Int
    let text: String
    var isHost = false
    var isDonation = false
    var replyTo: String? = nil
    var replyToHost = false
    var source: MessageSource? = nil
    var postedAt: Double = 0
}
struct Donation: Identifiable {
    let id = UUID()
    let participantID: Int
    let name: String
    let amount: Int
    let message: String
    let avatar: String
    let color: Int
    let displayDuration: Double
    let returning: Bool
}

/// Used topic state for the offline library: answers are consumed once per session.
private struct TopicUse {
    var lastStarted = -10000.0
    var openersUsed: Set<Int> = []
    var answersUsed: Set<Int> = []
}
private struct ActiveTopic {
    let topicID: String
    let opener: Int
    let openerMessage: UUID
    let startedAt: Double
    var answerers: Set<Int>
}

// This engine has no network, microphone or payment access.
// Pipeline: observations (host text, manual moments, camera cues) → audience & attention →
// planned messages with author, addressee, cause and time window → optional on-device wording → delivery.
struct Simulation {
    static let hostLabel = "host"
    private(set) var settings: Settings
    private(set) var messages: [ChatMessage] = []
    private(set) var donation: Donation?
    private(set) var donationQueue: [Donation] = []
    private(set) var total = 0
    private(set) var viewers: Int
    /// Visible stream time. Internal scheduling uses `now`, which also covers the warm-up before the first frame.
    private(set) var elapsed: Double = 0
    private(set) var context: StreamEvent?
    private(set) var visualScene: VisualScene?
    private(set) var running = true
    private(set) var uniqueMessages = 0
    private(set) var contentExhausted = false
    private(set) var donationCount = 0
    private(set) var nextDonation: Double = 70
    private(set) var metrics = EngineMetrics()
    private(set) var audience: Audience
    private(set) var pending: [PlannedMessage] = []
    private(set) var lastDonorID: Int?
    /// B5: every gift of this session, newest last (bounded).
    private(set) var giftHistory: [Donation] = []
    private(set) var acceptedLocalMessages = 0
    private(set) var now: Double = 0
    private(set) var breakActive = false
    private var random: StreamRandom
    private var donationClock = 0.0, bannerClock = 0.0, bannerGap = 0.0
    private var contextClock = 0.0, scenarioClock = 0.0, viewerClock = 0.0, sceneAge = 0.0, presenceClock = 0.0, paceClock = 0.0
    private var sceneSince = 0.0
    private var sceneCommented: [VisualScene: Double] = [:]
    private var manualOverrideUntil = -1000.0, cameraEventUntil = -1000.0
    private var cameraContextActive = false
    private var eventEpoch = 0
    private var step = 0, audienceTarget: Int
    private var budget = 0.0, pace = 1.0
    private var idleSince: Double?
    private var topicUse: [String: TopicUse] = [:]
    private var activeTopics: [ActiveTopic] = []
    private var memory = TextMemory(), tipMemory = TextMemory()
    private var recentShort: [String] = []
    private var visibleIDs: [UUID] = []
    private var aiAmbient: [String] = [], aiTips: [String] = []
    private var aiScene: Scenario?
    private var dollarSampler = DollarSampler()
    private var thankedDonations: Set<UUID> = []
    private var lastHostIntent: HostIntent?

    init(settings: Settings = Settings(), seed: UInt64 = UInt64.random(in: 0...UInt64.max), community: [Participant]? = nil) {
        self.settings = settings; self.settings.normalize()
        var random = StreamRandom(state: seed)
        audience = Audience(restoring: community, using: &random)
        // A7: the room does not always open at the same size.
        let start = Int(260 * random.logNormal(sigma: 0.55)) + 180
        viewers = min(4000, start); audienceTarget = viewers
        self.random = random
        audience.seat(chatterTarget, now: 0, using: &self.random)
        scheduleDonation()
        // Warm-up: the room was already talking before the host looked at it. Nothing in the warm-up reacts to the host.
        for _ in 0..<160 { advance(0.25) }
        elapsed = 0; donationClock = 0; scenarioClock = 0
    }

    // MARK: Public state

    var activeScenario: Scenario {
        guard settings.scenario == .automatic else { return settings.scenario }
        // C2: a briefly visible object does not repaint the whole room.
        if let visualScene, now - sceneSince >= 40 { return visualScene.scenario }
        return .cozy
    }
    var donationProgress: Double { donation.map { max(0, 1 - bannerClock / $0.displayDuration) } ?? 0 }
    var chatterTarget: Int { min(45, max(4, Int(3 + 2 * (Double(viewers) / 8).squareRoot()))) }
    var presentChatters: Int { audience.presentCount }
    var communitySnapshot: CommunitySnapshot { audience.snapshot }
    var pendingModelSlots: Int { pending.filter { $0.writerRequested && !$0.writtenByModel }.count }

    mutating func togglePause() { running.toggle() }
    mutating func pause() { running = false }
    mutating func resume() { running = true }

    mutating func apply(_ value: Settings) {
        let old = settings
        settings = value; settings.normalize()
        if old.scenario != settings.scenario {
            endMoment(); step = 0; scenarioClock = 0; activeTopics = []
            let stale = pending.filter { $0.source == .topicOpener }
            pending.removeAll { $0.source == .topicOpener }
            for message in stale { metrics.drop(message, .staleContext) }
        }
        if !settings.cameraReactions { clearCameraContext() }
        if old.streamTitle != settings.streamTitle { aiAmbient = [] }
        if old.donationsPerMinute != settings.donationsPerMinute { donationClock = 0; scheduleDonation() }
    }
    mutating func clearCameraContext() {
        visualScene = nil
        if cameraContextActive { endMoment() }
    }
    mutating func observeScene(_ value: VisualScene?) {
        guard running, settings.cameraReactions else { return }
        sceneAge = 0
        guard visualScene != value else { return }
        visualScene = value; sceneSince = now
        if let value {
            // Comment on the same kind of thing at most once every five minutes.
            if now - (sceneCommented[value] ?? -1000) >= 300 { sceneCommented[value] = now; reactToCamera(value.event) }
        } else if cameraContextActive { endMoment() }
    }
    mutating func reactToCamera(_ event: StreamEvent) {
        guard settings.cameraReactions, running, now >= manualOverrideUntil, now >= cameraEventUntil else { return }
        if breakActive && (event == .faceAway || event == .faceBack) { return }
        cameraEventUntil = now + 15
        trigger(event, fromCamera: true)
    }

    /// Marks a moment. Nothing is posted synchronously: viewers notice it, think and type first.
    mutating func trigger(_ event: StreamEvent, fromCamera: Bool = false) {
        guard running else { return }
        if !fromCamera { manualOverrideUntil = now + 15 }
        endMoment()
        cameraContextActive = fromCamera
        context = event; contextClock = 0
        switch event {
        case .win: audienceTarget += 20 + random.index(50)
        case .breakTime: audienceTarget = max(150, audienceTarget - 45); breakActive = true
        case .returnLive: breakActive = false
        default: break
        }
        planEventReactions(event, fromCamera: fromCamera)
        if event == .win && settings.donationsPerMinute > 0 && random.chance(0.3) {
            nextDonation = min(nextDonation, donationClock + 8 + random.unit() * 20)
        }
    }

    /// The host's own message appears immediately; replies are planned with reading and typing time.
    mutating func send(_ text: String) {
        let value = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
        guard running, !value.isEmpty else { return }
        let hostMessage = ChatMessage(id: UUID(), participantID: nil, name: settings.channelName, avatar: String(settings.channelName.prefix(2)).uppercased(), color: 0, text: value, isHost: true, postedAt: now)
        append(hostMessage)
        let intent = HostIntent.parse(value)
        lastHostIntent = intent
        if let event = intent.event { trigger(event) }
        planHostReplies(to: hostMessage, intent: intent)
    }

    /// B6: the host thanks the latest donor. The donor may answer later; nobody answers instantly.
    @discardableResult mutating func thankLatestDonor() -> Bool {
        guard running, let id = lastDonorID, let donor = audience[id] else { return false }
        send("Thank you, @\(donor.name)!")
        return true
    }

    // MARK: On-device writer (E2/E3)

    /// Lines the app has already scheduled and would like worded freshly. The model never picks authors, timing or amounts.
    mutating func makeWritingRequest(maxSlots: Int = 4) -> WritingRequest? {
        guard running, settings.localWriting else { return nil }
        var slots: [WritingSlot] = []
        for index in pending.indices where slots.count < maxSlots {
            let message = pending[index]
            guard message.writerEligible, !message.writerRequested, message.due - now >= 3.5, message.expires - now >= 8,
                  let person = audience[message.participant] else { continue }
            let kind: WritingSlot.Kind = message.source == .hostReply ? .replyToHost : message.source == .eventReaction ? .eventReaction : .answerViewer
            slots.append(WritingSlot(id: message.id, kind: kind, voice: person.voice.summary, about: message.prompt, maxLength: person.voice.brevity > 0.66 ? 60 : 120))
            pending[index].writerRequested = true
        }
        if aiScene != activeScenario { aiAmbient = []; aiScene = activeScenario }
        let ambient = aiAmbient.count < 4 ? 6 : 0
        guard !slots.isEmpty || ambient > 0 else { return nil }
        let recent = messages.suffix(16).map { ($0.isHost ? Self.hostLabel : "viewer") + ": " + $0.text }
        let hint = context?.fact ?? visualScene?.fact ?? "No specific action is confirmed."
        return WritingRequest(category: activeScenario.category, streamTitle: settings.streamTitle, visualHint: hint, recentChat: recent, slots: slots, ambientCount: ambient)
    }

    /// Returns how many generated lines were accepted. Lines for messages that were already shown,
    /// dropped or expired are discarded rather than shown late.
    @discardableResult mutating func acceptWriting(_ result: WritingResult, for request: WritingRequest) -> Int {
        guard running, settings.localWriting else { return 0 }
        var accepted = 0
        for slot in request.slots {
            guard let raw = result.slotTexts[slot.id], let index = pending.firstIndex(where: { $0.id == slot.id }) else { continue }
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard pending[index].expires > now + 1, line.count <= slot.maxLength, TextMemory.valid(line, maxLength: slot.maxLength), !mentionsMoney(line), memory.accept(line) else { continue }
            pending[index].text = line; pending[index].writtenByModel = true
            accepted += 1
        }
        if request.ambientCount > 0 && aiScene == activeScenario {
            var added = 0
            for line in result.ambient.prefix(8) {
                let value = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if TextMemory.valid(value, maxLength: 120), !mentionsMoney(value), memory.allows(value), !aiAmbient.contains(value) { aiAmbient.append(value); added += 1 }
            }
            aiAmbient = Array(aiAmbient.suffix(12))
            accepted += added
        }
        metrics.modelAccepted(accepted)
        return accepted
    }
    /// Older callers: a model batch of free lines and tip notes.
    mutating func acceptTips(_ tips: [String]) {
        for tip in tips.prefix(4) where TextMemory.valid(tip, maxLength: 100) && tipMemory.allows(tip) && !mentionsMoney(tip) { aiTips.append(tip) }
        aiTips = Array(aiTips.suffix(8))
    }

    // MARK: Gifts

    @discardableResult mutating func donate() -> Bool {
        guard running, donationQueue.count < 12 else { return false }
        guard let donorID = pickDonor(), let donor = audience[donorID] else { return false }
        let amount = dollarSampler.next(minimum: Int(settings.minAmount), maximum: Int(settings.maxAmount), using: &random)
        let returning = donor.sessionTips + donor.pastTips > 0
        // Silent tips are normal; do not disguise reused copy with punctuation or emoji.
        var note = ""
        if random.unit() >= 0.28 {
            while !aiTips.isEmpty && note.isEmpty {
                let candidate = aiTips.removeFirst()
                if tipMemory.accept(candidate) { note = candidate }
            }
            if note.isEmpty {
                var keys: [String] = []
                if returning && random.chance(0.5) { keys.append("return") }
                if let context, context == .win || context == .fail { keys.append(context.rawValue) }
                if amount >= 500 { keys.append("big") }
                keys += [activeScenario.rawValue, "any"]
                for key in keys where note.isEmpty {
                    let choices = (ChatContent.tipNotes[key] ?? []).shuffled(using: &random)
                    if let candidate = choices.first(where: { tipMemory.allows($0) }) { tipMemory.accept(candidate); note = candidate }
                }
                if note.isEmpty {
                    let fallback = ConversationLibrary.tipLines(event: nil, scenario: activeScenario, large: amount >= 500).shuffled(using: &random)
                    if let candidate = fallback.first(where: { tipMemory.allows($0) }) { tipMemory.accept(candidate); note = candidate }
                }
            }
        }
        let duration = max(settings.tipDuration, min(10, 4 + Double(note.count) * 0.035)) + (amount >= 500 ? 1 : 0)
        let gift = Donation(participantID: donorID, name: donor.name, amount: amount, message: note, avatar: donor.avatar, color: donor.color, displayDuration: duration, returning: returning)
        total += amount; donationCount += 1
        let time = now
        audience.update(donorID) { $0.sessionTips += 1; $0.sessionTipTotal += amount; $0.lastSpokeAt = time; $0.messages += 1 }
        lastDonorID = donorID
        giftHistory.append(gift); if giftHistory.count > 200 { giftHistory.removeFirst(giftHistory.count - 200) }
        if donation == nil && donationQueue.isEmpty && bannerGap <= 0 { display(gift) } else { donationQueue.append(gift) }
        append(ChatMessage(id: UUID(), participantID: donorID, name: donor.name, avatar: donor.avatar, color: donor.color, text: USD.format(amount) + (note.isEmpty ? " tip" : " · " + note), isDonation: true, source: .gift, postedAt: now))
        return true
    }

    // MARK: Clock

    mutating func tick(_ delta: Double) {
        guard running, delta > 0, delta.isFinite else { return }
        let dt = min(delta, 1)
        elapsed += dt
        advance(dt)
    }

    private mutating func advance(_ dt: Double) {
        now += dt; donationClock += dt; bannerClock += dt; contextClock += dt
        scenarioClock += dt; viewerClock += dt; sceneAge += dt; presenceClock += dt; paceClock += dt
        bannerGap = max(0, bannerGap - dt)
        if let gift = donation, bannerClock >= gift.displayDuration {
            donation = nil; bannerClock = 0; bannerGap = 0.8
        } else if donation == nil && bannerGap <= 0 && !donationQueue.isEmpty { display(donationQueue.removeFirst()) }
        if context != nil && contextClock >= (cameraContextActive ? 12 : 25) && context != .breakTime { context = nil; cameraContextActive = false }
        if visualScene != nil && sceneAge >= 18 { clearCameraContext() }
        if viewerClock >= 3 { updateViewers(); viewerClock = 0 }
        if paceClock >= 5 {
            // A6: slow waves of busier and quieter chat instead of a metronome.
            pace = min(1.6, max(0.45, pace + (1 - pace) * 0.15 + random.gaussian() * 0.12)); paceClock = 0
        }
        if presenceClock >= 6 + random.unit() * 10 { updatePresence(); presenceClock = 0 }
        if settings.autoplay && scenarioClock >= 50 {
            let events = activeScenario.timeline; trigger(events[step % events.count]); step += 1; scenarioClock = 0
        }
        direct(dt)
        deliver(dt)
        if settings.donationsPerMinute > 0 && donationClock >= nextDonation && elapsed > 0 {
            if breakActive && random.chance(0.7) { nextDonation += 10 + random.unit() * 20 }
            else { donate(); donationClock = 0; scheduleDonation() }
        }
    }

    // MARK: Delivery

    private mutating func deliver(_ dt: Double) {
        var allowance = max(1, Int(dt / 0.25 + 0.5))
        pending.sort { $0.due < $1.due }
        var index = 0
        while index < pending.count && allowance > 0 {
            let message = pending[index]
            guard message.due <= now else { break }
            if let reason = dropReason(message) {
                pending.remove(at: index); metrics.drop(message, reason); continue
            }
            if let parent = message.replyToMessage, !isVisible(parent) {
                // The cause is not on screen yet: wait for it rather than answering into the void.
                pending[index].due = now + 0.8 + random.unit() * 1.5
                index += 1; continue
            }
            pending.remove(at: index)
            post(message); allowance -= 1
        }
    }
    private func dropReason(_ message: PlannedMessage) -> DropReason? {
        if now > message.expires { return .expired }
        if let epoch = message.eventEpoch, epoch != eventEpoch { return .staleContext }
        if let parent = message.replyToMessage, !isVisible(parent), !pending.contains(where: { $0.id == parent }) { return .staleContext }
        guard let person = audience[message.participant], person.present || message.source == .presence else { return .speakerLeft }
        return nil
    }
    private mutating func post(_ message: PlannedMessage) {
        guard let person = audience[message.participant] else { return }
        var replyName: String?
        var toHost = false
        switch message.addressee {
        case .host?: toHost = true; replyName = settings.channelName
        case .participant(let id)?: replyName = audience[id]?.name
        case nil: break
        }
        let styled = style(message.text, voice: person.voice, model: message.writtenByModel)
        append(ChatMessage(id: message.id, participantID: person.id, name: person.name, avatar: person.avatar, color: person.color, text: styled, replyTo: replyName, replyToHost: toHost, source: message.source, postedAt: now))
        let time = now
        audience.update(person.id) { $0.lastSpokeAt = time; $0.messages += 1 }
        if message.source == .viewerToHost { audience.update(person.id) { $0.openQuestion = message.text; $0.openQuestionAt = time } }
        metrics.record(message, at: now)
        if message.writtenByModel { acceptedLocalMessages += 1 }
        uniqueMessages += 1
        if Self.isShort(message.text) { recentShort.append(TextMemory.canonical(message.text)); if recentShort.count > 14 { recentShort.removeFirst() } }
    }
    private func isVisible(_ id: UUID) -> Bool { visibleIDs.contains(id) }
    private mutating func append(_ message: ChatMessage) {
        messages.append(message)
        visibleIDs.append(message.id)
        if visibleIDs.count > 400 { visibleIDs.removeFirst(visibleIDs.count - 400) }
        if messages.count > 160 { messages.removeFirst(messages.count - 160) }
    }
    private mutating func schedule(_ message: PlannedMessage) {
        guard pending.count < 60 else { metrics.drop(message, .queueFull); return }
        pending.append(message)
    }

    // MARK: Director (ambient conversation)

    private mutating func direct(_ dt: Double) {
        let activity = min(1.3, max(0.55, (Double(audience.presentCount) / 22).squareRoot()))
        let breakFactor = breakActive ? 0.45 : 1
        let studyFactor = activeScenario == .study ? 0.7 : 1
        budget = min(6, budget + settings.messagesPerMinute / 60 * dt * pace * activity * breakFactor * studyFactor)
        let queuedAmbient = pending.filter { $0.due > now && [.topicOpener, .topicAnswer, .topicFollowUp, .sideReaction, .viewerToHost, .ambientAI].contains($0.source) }.count
        guard budget >= 1, queuedAmbient < 8 else { return }
        activeTopics.removeAll { now - $0.startedAt > 150 }
        var options: [(Double, Int)] = []
        options.append((activeTopics.count < 2 ? 0.5 : 0.08, 0))
        if !activeTopics.isEmpty { options.append((0.22, 1)) }
        options.append((0.1, 2))
        if !aiAmbient.isEmpty { options.append((0.4, 3)) }
        options.append((0.08, 4))
        var roll = random.unit() * options.reduce(0) { $0 + $1.0 }
        var choice = options[0].1
        for (w, c) in options { roll -= w; if roll < 0 { choice = c; break } }
        var produced = 0
        switch choice {
        case 0: produced = startTopic()
        case 1: produced = lateAnswer()
        case 2: produced = viewerToHost()
        case 3: produced = ambientModelLine()
        default: produced = sideReaction()
        }
        if produced == 0 { produced = startTopic() }
        if produced == 0 { produced = lateAnswer() + viewerToHost() }
        if produced == 0 {
            if idleSince == nil { idleSince = now }
            if now - (idleSince ?? now) > 20 { contentExhausted = true }
            budget = max(0, budget - 0.5)
        } else {
            idleSince = nil; contentExhausted = false
            budget -= Double(min(produced, 3))
        }
    }

    private var sceneKeys: Set<String> { ["any", activeScenario.rawValue] }

    private mutating func startTopic() -> Int {
        let keys = sceneKeys
        let candidates = Self.allTopics.filter { topic in
            guard topic.scenes.contains(where: keys.contains) else { return false }
            let use = topicUse[topic.id] ?? TopicUse()
            return now - use.lastStarted > 1200 && use.openersUsed.count < topic.openers.count && topic.answers.count - use.answersUsed.count >= 1
                && !activeTopics.contains { $0.topicID == topic.id }
        }
        guard !candidates.isEmpty else { return 0 }
        let weights = candidates.map { topic -> Double in
            let specific = topic.scenes.contains(activeScenario.rawValue) ? 2.2 : 1
            let legacy = topic.id.hasPrefix("v5.") ? 0.35 : 1
            let fresh = (topicUse[topic.id]?.openersUsed.isEmpty ?? true) ? 1 : 0.4
            return specific * legacy * fresh
        }
        var roll = random.unit() * weights.reduce(0, +)
        var topic = candidates[0]
        for (t, w) in zip(candidates, weights) { roll -= w; if roll < 0 { topic = t; break } }
        var use = topicUse[topic.id] ?? TopicUse()
        let openerIndex = (0..<topic.openers.count).filter { !use.openersUsed.contains($0) && memory.allows(topic.openers[$0]) }
        guard let chosenOpener = random.pick(openerIndex),
              let openerID = audience.pickSpeaker(now: now, using: &random, weight: { 0.5 + $0.voice.curiosity }) else { return 0 }
        use.openersUsed.insert(chosenOpener); use.lastStarted = now
        let openerText = topic.openers[chosenOpener]
        memory.accept(openerText)
        let openerDue = now + 0.3 + random.unit() * 2
        let opener = PlannedMessage(participant: openerID, text: openerText, source: .topicOpener, addressee: nil, replyToMessage: nil, causeTime: now, earliest: now, due: openerDue, expires: openerDue + 30, eventEpoch: nil, topicID: topic.id, prompt: "", writerEligible: false)
        schedule(opener)
        var produced = 1
        var active = ActiveTopic(topicID: topic.id, opener: openerID, openerMessage: opener.id, startedAt: now, answerers: [openerID])
        let room = audience.presentCount
        let wanted = min(room - 1, random.count(weights: room < 8 ? [0.15, 0.4, 0.3, 0.15] : [0.08, 0.22, 0.3, 0.2, 0.12, 0.08]))
        var firstAnswer: (UUID, Double, Int)?
        for _ in 0..<max(0, wanted) {
            guard let answer = planAnswer(topic: topic, use: &use, active: &active, openerText: openerText, openerDue: openerDue) else { break }
            produced += 1
            if firstAnswer == nil || answer.1 < firstAnswer!.1 { firstAnswer = answer }
        }
        topicUse[topic.id] = use
        if let first = firstAnswer, !topic.followUps.isEmpty, random.chance(0.35),
           let line = topic.followUps.shuffled(using: &random).first(where: { memory.allows($0) }), let person = audience[openerID] {
            memory.accept(line)
            let due = first.1 + ReactionTiming.delay(voice: person.voice, kind: .reply, readText: "", replyLength: line.count, using: &random)
            schedule(PlannedMessage(participant: openerID, text: line, source: .topicFollowUp, addressee: nil, replyToMessage: first.0, causeTime: first.1, earliest: first.1 + 2, due: due, expires: due + 40, eventEpoch: nil, topicID: topic.id, prompt: "", writerEligible: false))
            produced += 1
        }
        activeTopics.append(active)
        return produced
    }

    /// One viewer answers the opener. Different people answer on their own schedule.
    private mutating func planAnswer(topic: ChatTopic, use: inout TopicUse, active: inout ActiveTopic, openerText: String, openerDue: Double) -> (UUID, Double, Int)? {
        guard let speaker = audience.pickSpeaker(now: now, excluding: active.answerers, using: &random), let person = audience[speaker] else { return nil }
        let available = (0..<topic.answers.count).filter { !use.answersUsed.contains($0) && memory.allows(topic.answers[$0]) }
        guard !available.isEmpty else { return nil }
        let chosen = pickByLength(available.map { topic.answers[$0] }, voice: person.voice)
        guard let lineIndex = available.first(where: { topic.answers[$0] == chosen }) else { return nil }
        use.answersUsed.insert(lineIndex); memory.accept(chosen)
        active.answerers.insert(speaker)
        let base = max(openerDue, now)
        let due = base + ReactionTiming.delay(voice: person.voice, kind: .reply, readText: openerText, replyLength: chosen.count, using: &random) + random.unit() * 6
        let answer = PlannedMessage(participant: speaker, text: chosen, source: .topicAnswer, addressee: .participant(active.opener), replyToMessage: active.openerMessage, causeTime: base, earliest: base + 2, due: due, expires: due + 60, eventEpoch: nil, topicID: topic.id, prompt: openerText, writerEligible: false)
        schedule(answer)
        // Occasionally someone reacts to an answer rather than to the opener.
        if random.chance(0.14), let reactor = audience.pickSpeaker(now: now, excluding: active.answerers, using: &random), let r = audience[reactor],
           let quick = shortLine(for: r.personality) {
            let qd = due + ReactionTiming.delay(voice: r.voice, kind: .quick, readText: chosen, replyLength: quick.count, using: &random)
            schedule(PlannedMessage(participant: reactor, text: quick, source: .sideReaction, addressee: .participant(speaker), replyToMessage: answer.id, causeTime: due, earliest: due + 1.2, due: qd, expires: qd + 20, eventEpoch: nil, topicID: topic.id, prompt: "", writerEligible: false))
        }
        return (answer.id, due, speaker)
    }

    private mutating func lateAnswer() -> Int {
        guard !activeTopics.isEmpty else { return 0 }
        let i = random.index(activeTopics.count)
        var active = activeTopics[i]
        guard isVisible(active.openerMessage), let topic = Self.topicByID[active.topicID], var use = topicUse[topic.id] else { return 0 }
        let openerText = messages.first { $0.id == active.openerMessage }?.text ?? ""
        let result = planAnswer(topic: topic, use: &use, active: &active, openerText: openerText, openerDue: now)
        topicUse[topic.id] = use; activeTopics[i] = active
        return result == nil ? 0 : 1
    }

    private mutating func viewerToHost() -> Int {
        guard !breakActive, !pending.contains(where: { $0.source == .viewerToHost }) else { return 0 }
        let lines = (random.chance(0.45) ? ChatContent.viewerToHost[activeScenario.rawValue] ?? [] : []) + (ChatContent.viewerToHost["any"] ?? [])
        guard let line = lines.shuffled(using: &random).first(where: { memory.allows($0) }),
              let speaker = audience.pickSpeaker(now: now, using: &random, weight: { $0.voice.curiosity + 0.1 }) else { return 0 }
        memory.accept(line)
        let due = now + 0.5 + random.unit() * 3
        schedule(PlannedMessage(participant: speaker, text: line, source: .viewerToHost, addressee: .host, replyToMessage: nil, causeTime: now, earliest: now, due: due, expires: due + 30, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
        return 1
    }

    private mutating func ambientModelLine() -> Int {
        while !aiAmbient.isEmpty {
            let line = aiAmbient.removeFirst()
            guard memory.accept(line), let speaker = audience.pickSpeaker(now: now, using: &random) else { continue }
            let due = now + 0.5 + random.unit() * 3
            var message = PlannedMessage(participant: speaker, text: line, source: .ambientAI, addressee: nil, replyToMessage: nil, causeTime: now, earliest: now, due: due, expires: due + 30, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false)
            message.writtenByModel = true
            schedule(message)
            return 1
        }
        return 0
    }

    /// A short reaction to a recent viewer line, addressed to that viewer.
    private mutating func sideReaction() -> Int {
        guard let target = messages.suffix(6).last(where: { !$0.isHost && !$0.isDonation && $0.participantID != nil && now - $0.postedAt < 20 && !Self.isShort($0.text) }),
              let targetID = target.participantID,
              let reactor = audience.pickSpeaker(now: now, excluding: [targetID], using: &random), let person = audience[reactor],
              let line = shortLine(for: person.personality) else { return 0 }
        let due = now + ReactionTiming.delay(voice: person.voice, kind: .quick, readText: target.text, replyLength: line.count, using: &random)
        schedule(PlannedMessage(participant: reactor, text: line, source: .sideReaction, addressee: .participant(targetID), replyToMessage: target.id, causeTime: now, earliest: now + 1, due: due, expires: due + 15, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
        return 1
    }

    // MARK: Host replies

    private mutating func planHostReplies(to host: ChatMessage, intent: HostIntent) {
        let text = host.text
        var responders: [Int] = []
        // Someone the host named is the most likely to answer, if they are around and looking.
        for mention in intent.mentions {
            if let person = audience.people.first(where: { $0.present && $0.name.lowercased() == mention }), random.chance(0.85) { responders.append(person.id) }
        }
        let room = audience.presentCount
        let weights: [Double]
        switch intent.kind {
        case .greeting: weights = [0.1, 0.3, 0.3, 0.2, 0.1]
        case .howAreYou: weights = [0.05, 0.25, 0.35, 0.25, 0.1]
        case .thanks: weights = [0.45, 0.4, 0.15]
        case .bye: weights = [0.05, 0.2, 0.3, 0.3, 0.15]
        case .yesNoQuestion, .choice: weights = [0.08, 0.25, 0.3, 0.22, 0.1, 0.05]
        case .openQuestion: weights = [0.12, 0.3, 0.3, 0.18, 0.1]
        case .statement: weights = [0.45, 0.35, 0.15, 0.05]
        case .nonEnglish: weights = [0.65, 0.35]
        }
        let extra = min(max(0, room - responders.count), random.count(weights: weights))
        for _ in 0..<extra {
            guard let id = audience.pickSpeaker(now: now, excluding: Set(responders), using: &random, weight: { $0.voice.attention }) else { break }
            responders.append(id)
        }
        // Whoever asked the host something recently may take this as the answer.
        let askers = audience.people.filter { $0.present && $0.openQuestion != nil && now - $0.openQuestionAt < 75 && !responders.contains($0.id) }
        let topic = Self.allTopics.first { !$0.hostKeywords.isEmpty && !intent.keywords.isDisjoint(with: $0.hostKeywords) }
        var leaning: [String: Int] = [:]
        for (order, id) in responders.enumerated() {
            guard let person = audience[id] else { continue }
            var line: String?
            var quick = false
            switch intent.kind {
            case .choice(let a, let b):
                if random.chance(0.75) {
                    let option = random.chance(0.5) ? a : b
                    leaning[option, default: 0] += 1
                    line = choiceLine(option, voice: person.voice)
                } else { line = hostLine("choice") }
            case .yesNoQuestion:
                if let topic, random.chance(0.5) { line = topicAnswer(topic, voice: person.voice) }
                if line == nil { line = hostLine(["yes", "yes", "no", "unsure", "unsure"][random.index(5)]) }
            case .openQuestion:
                if let topic { line = topicAnswer(topic, voice: person.voice) }
                if line == nil { line = hostLine("open") }
            case .greeting: line = hostLine("greeting"); quick = true
            case .howAreYou: line = hostLine("howAreYou")
            case .thanks: line = hostLine("thanks"); quick = true
            case .bye: line = hostLine("bye"); quick = true
            case .statement:
                if random.chance(0.4), let s = shortLine(for: person.personality) { line = s; quick = true } else { line = hostLine("statement") }
            case .nonEnglish: line = hostLine("nonEnglish")
            }
            guard let chosen = line else { continue }
            let kind: ReactionTiming.Kind = quick || Self.isShort(chosen) ? .quick : .reply
            var due = now + ReactionTiming.delay(voice: person.voice, kind: kind, readText: text, replyLength: chosen.count, using: &random)
            // Not everyone finishes at once; a named viewer tends to answer a bit sooner.
            if order > 0 { due += random.unit() * Double(order) * 2.5 }
            let earliest = now + (kind == .quick ? 1.3 : 2.6)
            due = max(due, earliest)
            let eligible: Bool
            switch intent.kind { case .openQuestion, .yesNoQuestion, .statement, .howAreYou: eligible = !quick; default: eligible = false }
            schedule(PlannedMessage(participant: id, text: chosen, source: .hostReply, addressee: .host, replyToMessage: host.id, causeTime: now, earliest: earliest, due: due, expires: due + 45, eventEpoch: nil, topicID: nil, prompt: text, writerEligible: eligible))
        }
        if let asker = askers.first, random.chance(0.45), intent.kind != .nonEnglish,
           let line = (["ah ok", "got it", "ty", "oh nice", "fair enough", "ahh ok", "makes sense", "cool cool"].filter { !recentShort.contains(TextMemory.canonical($0)) }).randomElement(using: &random) {
            let due = now + ReactionTiming.delay(voice: asker.voice, kind: .quick, readText: text, replyLength: line.count, using: &random) + 1
            schedule(PlannedMessage(participant: asker.id, text: line, source: .acknowledgement, addressee: .host, replyToMessage: host.id, causeTime: now, earliest: now + 1.5, due: due, expires: due + 30, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
            audience.update(asker.id) { $0.openQuestion = nil }
        }
        // A donor who was just thanked answers in their own time.
        if intent.kind == .thanks, let donorID = lastDonorID, let donor = audience[donorID], donor.present,
           intent.mentions.contains(donor.name.lowercased()) || intent.mentions.isEmpty, random.chance(0.8),
           let line = ChatContent.thanksReplies.shuffled(using: &random).first(where: { memory.allows($0) || Self.isShort($0) }) {
            if !Self.isShort(line) { memory.accept(line) }
            let due = now + ReactionTiming.delay(voice: donor.voice, kind: .reply, readText: text, replyLength: line.count, using: &random)
            pending.removeAll { $0.participant == donorID && $0.replyToMessage == host.id }
            schedule(PlannedMessage(participant: donorID, text: line, source: .thanks, addressee: .host, replyToMessage: host.id, causeTime: now, earliest: now + 2, due: due, expires: due + 40, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
            lastDonorID = nil
        }
    }

    private mutating func choiceLine(_ option: String, voice: Voice) -> String? {
        let templates = ["%@", "%@", "%@ tbh", "%@ always", "%@ for sure", "team %@", "%@, easy", "%@ obviously", "%@ every time", "%@ tonight", "%@, no contest", "def %@", "%@ please", "i'd say %@"]
        for template in templates.shuffled(using: &random) {
            let line = template.replacingOccurrences(of: "%@", with: option)
            if Self.isShort(line) ? !recentShort.contains(TextMemory.canonical(line)) : memory.accept(line) { return line }
        }
        return nil
    }
    private mutating func hostLine(_ key: String) -> String? {
        let lines = (ChatContent.hostReplies[key] ?? []).shuffled(using: &random)
        for line in lines {
            if Self.isShort(line) { if !recentShort.contains(TextMemory.canonical(line)) { return line } }
            else if memory.accept(line) { return line }
        }
        return nil
    }
    private mutating func topicAnswer(_ topic: ChatTopic, voice: Voice) -> String? {
        var use = topicUse[topic.id] ?? TopicUse()
        let available = (0..<topic.answers.count).filter { !use.answersUsed.contains($0) && memory.allows(topic.answers[$0]) }
        guard !available.isEmpty else { return nil }
        let chosen = pickByLength(available.map { topic.answers[$0] }, voice: voice)
        if let index = available.first(where: { topic.answers[$0] == chosen }) { use.answersUsed.insert(index) }
        memory.accept(chosen); topicUse[topic.id] = use
        return chosen
    }

    // MARK: Moments

    private mutating func planEventReactions(_ event: StreamEvent, fromCamera: Bool) {
        eventEpoch += 1
        let key = event.rawValue
        let room = audience.presentCount
        let count: Int
        if fromCamera { count = min(room, random.count(weights: [0.3, 0.45, 0.2, 0.05])) }
        else {
            switch event {
            case .win, .laugh: count = min(room, random.count(weights: [0.02, 0.13, 0.25, 0.25, 0.2, 0.15]))
            case .breakTime, .returnLive: count = min(room, random.count(weights: [0.1, 0.35, 0.35, 0.2]))
            default: count = min(room, random.count(weights: [0.05, 0.25, 0.35, 0.25, 0.1]))
            }
        }
        var used: Set<Int> = []
        let quickShare: Double = [.win, .laugh, .fail].contains(event) ? 0.55 : fromCamera ? 0.15 : 0.3
        for order in 0..<count {
            guard let id = audience.pickSpeaker(now: now, excluding: used, using: &random, weight: { $0.voice.attention }), let person = audience[id] else { break }
            used.insert(id)
            var line: String?
            var quick = random.chance(quickShare)
            if quick { line = (ChatContent.events[key + ".quick"] ?? []).shuffled(using: &random).first { !recentShort.contains(TextMemory.canonical($0)) } }
            if line == nil {
                quick = false
                line = (ChatContent.events[key] ?? []).shuffled(using: &random).first { memory.allows($0) }
                if let line { memory.accept(line) }
            }
            guard let chosen = line else { continue }
            let kind: ReactionTiming.Kind = quick ? .quick : .comment
            let confirm = fromCamera ? 1.5 : 0.6
            var due = now + confirm + ReactionTiming.delay(voice: person.voice, kind: kind, readText: "", replyLength: chosen.count, using: &random)
            due += Double(order) * random.unit() * 1.5
            let earliest = now + (fromCamera ? 2 : 1.2)
            due = max(due, earliest)
            schedule(PlannedMessage(participant: id, text: chosen, source: .eventReaction, addressee: nil, replyToMessage: nil, causeTime: now, earliest: earliest, due: due, expires: due + (fromCamera ? 10 : 18), eventEpoch: eventEpoch, topicID: nil, prompt: event.fact, writerEligible: !quick))
        }
    }
    /// Ends the current moment; reactions still waiting for it are cancelled, other conversation continues.
    private mutating func endMoment() {
        context = nil; cameraContextActive = false
        eventEpoch += 1
    }

    // MARK: Audience dynamics

    private mutating func updateViewers() {
        audienceTarget = min(12000, max(120, audienceTarget + Int((random.gaussian() * 4).rounded()) + (breakActive ? -2 : 0)))
        viewers = max(1, viewers + (audienceTarget - viewers) / 12 + random.index(7) - 3)
    }
    private mutating func updatePresence() {
        let changes = audience.balance(target: chatterTarget, now: now, using: &random)
        for id in changes.joined where random.chance(0.22) {
            planPresence(id, key: "join")
        }
        for id in changes.left where random.chance(0.12) {
            planPresence(id, key: "leave", immediate: true)
        }
    }
    private mutating func planPresence(_ id: Int, key: String, immediate: Bool = false) {
        guard let person = audience[id], let line = (ChatContent.presence[key] ?? []).shuffled(using: &random).first(where: { Self.isShort($0) ? !recentShort.contains(TextMemory.canonical($0)) : memory.allows($0) }) else { return }
        if !Self.isShort(line) { memory.accept(line) }
        let due = now + (immediate ? 0.1 : 2 + random.unit() * 8)
        schedule(PlannedMessage(participant: person.id, text: line, source: .presence, addressee: nil, replyToMessage: nil, causeTime: now, earliest: now, due: due, expires: due + 20, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
    }
    private mutating func pickDonor() -> Int? {
        let recentSpeakers = Set(messages.suffix(30).compactMap(\.participantID))
        if let id = audience.pickSpeaker(now: now + 100, using: &random, weight: { person in
            let history = person.sessionTips + person.pastTips > 0 ? 2.0 : 1
            let engaged = recentSpeakers.contains(person.id) ? 1.6 : 1
            return (0.25 + person.voice.generosity) * history * engaged / max(0.2, person.voice.chattiness)
        }) { return id }
        guard let id = audience.add(regular: false, using: &random) else { return nil }
        let time = now
        audience.update(id) { $0.presence = .present; $0.joinedAt = time }
        return id
    }

    // MARK: Helpers

    private mutating func display(_ gift: Donation) {
        donation = gift; bannerClock = 0
        let large = gift.amount >= 500
        let reactions = random.count(weights: large ? [0.05, 0.3, 0.35, 0.3] : [0.45, 0.4, 0.15])
        var used: Set<Int> = [gift.participantID]
        for order in 0..<reactions {
            guard let id = audience.pickSpeaker(now: now, excluding: used, using: &random), let person = audience[id],
                  let line = (ChatContent.giftReactions[large ? "large" : "small"] ?? []).shuffled(using: &random).first(where: { Self.isShort($0) ? !recentShort.contains(TextMemory.canonical($0)) : memory.allows($0) }) else { continue }
            used.insert(id)
            if !Self.isShort(line) { memory.accept(line) }
            let due = now + 1.5 + Double(order) * random.unit() * 2 + ReactionTiming.delay(voice: person.voice, kind: .quick, readText: gift.message, replyLength: line.count, using: &random)
            schedule(PlannedMessage(participant: id, text: line, source: .giftReaction, addressee: .participant(gift.participantID), replyToMessage: nil, causeTime: now, earliest: now + 1.5, due: due, expires: due + 15, eventEpoch: nil, topicID: nil, prompt: "", writerEligible: false))
        }
    }
    private mutating func scheduleDonation() {
        nextDonation = settings.donationsPerMinute > 0 ? (60 / settings.donationsPerMinute) * (0.75 + random.unit() * 0.6) : .infinity
    }
    private mutating func shortLine(for personality: Personality) -> String? {
        let keys: [String]
        switch personality {
        case .joker: keys = ["laugh", "laugh", "surprise", "agree"]
        case .supporter: keys = ["agree", "hype", "sympathy", "laugh"]
        case .analyst: keys = ["question", "neutral", "agree", "disagree"]
        case .skeptic: keys = ["disagree", "neutral", "question", "laugh"]
        }
        let key = keys[random.index(keys.count)]
        return (ChatContent.short[key] ?? []).shuffled(using: &random).first { !recentShort.contains(TextMemory.canonical($0)) }
    }
    private mutating func pickByLength(_ lines: [String], voice: Voice) -> String {
        let weighted = lines.map { line -> Double in
            let short = line.count <= 30
            return voice.brevity > 0.6 ? (short ? 3 : 0.6) : voice.brevity < 0.35 ? (short ? 0.7 : 2) : 1
        }
        var roll = random.unit() * weighted.reduce(0, +)
        for (line, w) in zip(lines, weighted) { roll -= w; if roll < 0 { return line } }
        return lines[lines.count - 1]
    }
    /// A participant's habits: some write casually in lowercase without a full stop. Wording is never changed.
    private func style(_ text: String, voice: Voice, model: Bool) -> String {
        guard voice.casual > 0.6, let first = text.first, first.isUppercase else { return text }
        let firstWord = text.prefix { $0 != " " }
        guard firstWord != "I", !firstWord.hasPrefix("I'"), firstWord.count > 1 ? !firstWord.dropFirst().contains(where: \.isUppercase) : true else { return text }
        var value = text.prefix(1).lowercased() + text.dropFirst()
        if value.hasSuffix(".") && !value.hasSuffix("..") { value.removeLast() }
        return value
    }
    private func mentionsMoney(_ text: String) -> Bool { text.contains("$") || text.lowercased().contains("usd") }
    static func isShort(_ text: String) -> Bool { text.count <= 16 && text.split(separator: " ").count <= 3 }

    static let allTopics: [ChatTopic] = ChatContent.topics + ConversationLibrary.legacyTopics
    static let topicByID: [String: ChatTopic] = Dictionary(allTopics.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
}

enum USD {
    static func format(_ amount: Int) -> String {
        "$" + amount.formatted(.number.locale(Locale(identifier: "en_US")))
    }
}
struct DollarSampler {
    private var recent: [Int] = []
    mutating func next(minimum: Int = 10, maximum: Int = 900, using random: inout StreamRandom) -> Int {
        let low = min(900, max(10, minimum)), high = min(900, max(low, maximum))
        // 80% standard support, 17% small tips, 3% occasional larger gifts.
        let bands: [(ClosedRange<Int>, Double)] = [(100...200, 0.80), (10...99, 0.17), (201...900, 0.03)]
        var choices: [([Int], Double)] = []
        for (range, weight) in bands {
            let lo = max(low, range.lowerBound), hi = min(high, range.upperBound)
            guard lo <= hi else { continue }
            let available = (lo...hi).filter { !recent.contains($0) }
            if !available.isEmpty { choices.append((available, weight)) }
        }
        let value: Int
        if choices.isEmpty { value = low }
        else {
            var roll = random.unit() * choices.reduce(0) { $0 + $1.1 }
            var pool = choices.last!.0
            for (candidate, weight) in choices {
                roll -= weight
                if roll < 0 { pool = candidate; break }
            }
            let rounded = pool.filter { $0 % 5 == 0 }
            let selection = !rounded.isEmpty && random.unit() < 0.85 ? rounded : pool
            value = selection[random.index(selection.count)]
        }
        recent.append(value)
        if recent.count > 10 { recent.removeFirst() }
        return value
    }
}
