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
    var schemaVersion = 5
    var messagesPerMinute: Double = 24
    var donationsPerMinute: Double = 0.85
    var minAmount: Double = 10
    var maxAmount: Double = 900
    var scenario: Scenario = .automatic
    var autoplay = false
    var cameraReactions = true
    var localWriting = true
    var tipDuration: Double = 7
    var channelName = "nightshift"
    var streamTitle = "Just one more minute"
    init() {}
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, messagesPerMinute, donationsPerMinute, minAmount, maxAmount, scenario, autoplay, cameraReactions, localWriting, tipDuration, channelName, streamTitle
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
        tipDuration = (try? v.decode(Double.self, forKey: .tipDuration)) ?? tipDuration
        channelName = (try? v.decode(String.self, forKey: .channelName)) ?? channelName
        streamTitle = (try? v.decode(String.self, forKey: .streamTitle)) ?? streamTitle
        normalize()
    }
    mutating func normalize() {
        schemaVersion = 5
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
}
struct Persona {
    let name: String
    let avatar: String
    let color: Int
    let personality: Personality
}
struct ChatMessage: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let color: Int
    let text: String
    var isHost = false
    var isDonation = false
    var replyTo: String? = nil
}
struct Donation: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int
    let message: String
    let avatar: String
    let color: Int
    let displayDuration: Double
}
struct WritingContext: Equatable {
    let token: UUID
    let scenario: Scenario
    let streamTitle: String
    let fact: String
    let hostMessage: String
    let recentMessages: [String]
}
struct WritingBatch: Codable {
    let messages: [String]
    let tips: [String]
    static func parse(_ text: String) -> WritingBatch? {
        guard text.utf8.count <= 12000, let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start <= end else { return nil }
        return try? JSONDecoder().decode(Self.self, from: Data(text[start...end].utf8))
    }
}

// This engine has no network, microphone or payment access.
struct Simulation {
    private(set) var settings: Settings
    private(set) var messages: [ChatMessage] = []
    private(set) var donation: Donation?
    private(set) var donationQueue: [Donation] = []
    private(set) var total = 0
    private(set) var viewers = 1284
    private(set) var elapsed: Double = 0
    private(set) var context: StreamEvent?
    private(set) var visualScene: VisualScene?
    private(set) var running = true
    private(set) var uniqueMessages = 0
    private(set) var contentExhausted = false
    private(set) var donationCount = 0
    private(set) var nextChat: Double = 1
    private(set) var nextDonation: Double = 70
    private(set) var contextToken = UUID()
    private(set) var acceptedLocalMessages = 0
    private var random: StreamRandom
    private var chatClock = 0.0, donationClock = 0.0, bannerClock = 0.0, bannerGap = 0.0
    private var contextClock = 0.0, scenarioClock = 0.0, viewerClock = 0.0, sceneAge = 0.0
    private var manualOverrideUntil = 0.0, cameraEventUntil = 0.0
    private var cameraContextActive = false
    private var lastHostMessage = ""
    private var hostMessageAge = 0.0
    private var eventBudget = 0
    private var step = 0, audienceTarget = 1284
    private var usedNames: Set<String> = []
    private var usedThreads: Set<String> = []
    private var episode: [String] = []
    private var replyName: String?
    private var localMessages: [String] = [], localTips: [String] = []
    private var chatMemory = TextMemory(), tipMemory = TextMemory()
    private var dollarSampler = DollarSampler()
    private var giftReactionDue: Double?
    private var giftReactionName = ""
    private var giftReactionAmount = 0

    init(settings: Settings = Settings(), seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.settings = settings; self.settings.normalize()
        random = StreamRandom(state: seed)
        scheduleChat(); scheduleDonation()
        for _ in 0..<5 { addReaction() }
    }
    var activeScenario: Scenario { settings.scenario == .automatic ? (visualScene?.scenario ?? .cozy) : settings.scenario }
    var writingContext: WritingContext {
        WritingContext(token: contextToken, scenario: activeScenario, streamTitle: settings.streamTitle, fact: context?.fact ?? (visualScene?.fact ?? "No specific action is confirmed. Do not invent an action, sound, location or emotion."), hostMessage: lastHostMessage, recentMessages: messages.suffix(24).map(\.text))
    }
    var needsWriting: Bool { running && settings.localWriting && localMessages.count < 5 }
    var donationProgress: Double { donation.map { max(0, 1 - bannerClock / $0.displayDuration) } ?? 0 }
    mutating func togglePause() { running.toggle() }
    mutating func pause() { running = false }
    mutating func apply(_ value: Settings) {
        let old = settings
        settings = value; settings.normalize()
        if old.scenario != settings.scenario {
            context = nil; cameraContextActive = false; eventBudget = 0; step = 0; scenarioClock = 0; invalidateWriting()
        }
        if !settings.cameraReactions { clearCameraContext() }
        if old.localWriting != settings.localWriting || old.streamTitle != settings.streamTitle { invalidateWriting() }
        chatClock = 0; donationClock = 0; scheduleChat(); scheduleDonation()
    }
    private mutating func invalidateWriting() {
        contextToken = UUID(); localMessages = []; localTips = []; episode = []; replyName = nil
    }
    mutating func clearCameraContext() {
        let hadScene = visualScene != nil
        visualScene = nil
        if cameraContextActive { context = nil; cameraContextActive = false; eventBudget = 0; invalidateWriting() }
        else if hadScene { invalidateWriting() }
    }
    mutating func observeScene(_ value: VisualScene?) {
        guard running, settings.cameraReactions else { return }
        sceneAge = 0
        guard visualScene != value else { return }
        visualScene = value
        invalidateWriting()
        if let value { reactToCamera(value.event) }
        else if cameraContextActive { context = nil; eventBudget = 0; cameraContextActive = false }
    }
    mutating func reactToCamera(_ event: StreamEvent) {
        guard settings.cameraReactions, running, elapsed >= manualOverrideUntil, elapsed >= cameraEventUntil else { return }
        cameraEventUntil = elapsed + 15
        trigger(event, fromCamera: true)
    }
    mutating func trigger(_ event: StreamEvent, fromCamera: Bool = false) {
        guard running else { return }
        if !fromCamera { manualOverrideUntil = elapsed + 15 }
        cameraContextActive = fromCamera
        context = event; contextClock = 0; eventBudget = fromCamera ? 2 : 4
        invalidateWriting()
        if event == .win { audienceTarget += 20 + random.index(50) }
        if event == .breakTime { audienceTarget = max(150, audienceTarget - 45) }
        addReaction(); chatClock = 0; scheduleChat()
    }
    mutating func send(_ text: String) {
        let value = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
        guard running, !value.isEmpty else { return }
        append(.init(name: settings.channelName, avatar: String(settings.channelName.prefix(2)).uppercased(), color: 0, text: value, isHost: true))
        lastHostMessage = value; hostMessageAge = 0; invalidateWriting()
        let words = value.lowercased().split { !$0.isLetter }.map(String.init)
        let normalized = value.lowercased().replacingOccurrences(of: "’", with: "'")
        let negative = normalized.contains("won't") || ["not", "never", "didn", "haven", "не"].contains { words.contains($0) }
        if !negative && (words.contains("won") || words.contains("победа")) { trigger(.win) }
        else if words.contains("haha") || words.contains("хаха") { trigger(.laugh) }
        else if words.contains("brb") || words.contains("перерыв") { trigger(.breakTime) }
        else { chatClock = 0; nextChat = 1.4 + random.unit() * 1.5 }
    }
    @discardableResult mutating func acceptWriting(_ batch: WritingBatch, for token: UUID) -> Bool {
        guard running, settings.localWriting, token == contextToken else { return false }
        for line in batch.messages.prefix(10) where TextMemory.valid(line, maxLength: 170) && !localMessages.contains(line) {
            if chatMemory.allows(line) { localMessages.append(line) }
        }
        for line in batch.tips.prefix(4) where TextMemory.valid(line, maxLength: 100) && !localTips.contains(line) {
            if tipMemory.allows(line) { localTips.append(line) }
        }
        localMessages = Array(localMessages.prefix(16)); localTips = Array(localTips.prefix(8))
        return !localMessages.isEmpty
    }
    @discardableResult mutating func donate() -> Bool {
        guard running, donationQueue.count < 12, let person = makePersona() else { return false }
        let amount = dollarSampler.next(minimum: Int(settings.minAmount), maximum: Int(settings.maxAmount), using: &random)
        // Silent tips are normal; do not disguise reused copy with punctuation or emoji.
        var note = ""
        if random.unit() >= 0.28 {
            while !localTips.isEmpty && note.isEmpty {
                let candidate = localTips.removeFirst()
                if tipMemory.accept(candidate) { note = candidate }
            }
            if note.isEmpty {
                let choices = ConversationLibrary.tipLines(event: context, scenario: activeScenario, large: amount >= 500).shuffled(using: &random)
                if let candidate = choices.first(where: { tipMemory.allows($0) }) { tipMemory.accept(candidate); note = candidate }
            }
        }
        let duration = max(settings.tipDuration, min(10, 4 + Double(note.count) * 0.035)) + (amount >= 500 ? 1 : 0)
        let gift = Donation(name: person.name, amount: amount, message: note, avatar: person.avatar, color: person.color, displayDuration: duration)
        total += amount; donationCount += 1
        if donation == nil && donationQueue.isEmpty && bannerGap <= 0 { display(gift) } else { donationQueue.append(gift) }
        append(.init(name: person.name, avatar: person.avatar, color: person.color, text: USD.format(amount) + (note.isEmpty ? " tip" : " · " + note), isDonation: true))
        return true
    }
    mutating func tick(_ delta: Double) {
        guard running, delta > 0, delta.isFinite else { return }
        let dt = min(delta, 1)
        elapsed += dt; chatClock += dt; donationClock += dt; bannerClock += dt; contextClock += dt
        scenarioClock += dt; viewerClock += dt; sceneAge += dt; hostMessageAge += dt
        bannerGap = max(0, bannerGap - dt)
        if let gift = donation, bannerClock >= gift.displayDuration {
            donation = nil; bannerClock = 0; bannerGap = 0.8
        } else if donation == nil && bannerGap <= 0 && !donationQueue.isEmpty { display(donationQueue.removeFirst()) }
        if let due = giftReactionDue, elapsed >= due { giftReactionDue = nil; addGiftReaction() }
        if context != nil && contextClock >= (cameraContextActive ? 9 : 20) {
            context = nil; cameraContextActive = false; eventBudget = 0; invalidateWriting()
        }
        if visualScene != nil && sceneAge >= 18 { clearCameraContext() }
        if !lastHostMessage.isEmpty && hostMessageAge > 45 { lastHostMessage = ""; invalidateWriting() }
        if viewerClock >= 3 {
            audienceTarget = min(12000, max(150, audienceTarget + random.index(15) - 7))
            viewers = max(1, viewers + (audienceTarget - viewers) / 12 + random.index(7) - 3); viewerClock = 0
        }
        if settings.autoplay && scenarioClock >= 50 {
            let events = activeScenario.timeline; trigger(events[step % events.count]); step += 1; scenarioClock = 0
        }
        if chatClock >= nextChat { addReaction(); chatClock = 0; scheduleChat() }
        if settings.donationsPerMinute > 0 && donationClock >= nextDonation { donate(); donationClock = 0; scheduleDonation() }
    }
    private mutating func display(_ gift: Donation) {
        donation = gift; bannerClock = 0
        if random.unit() < (gift.amount >= 500 ? 0.95 : 0.6) {
            giftReactionDue = elapsed + 2 + random.unit() * 2; giftReactionName = gift.name; giftReactionAmount = gift.amount
        }
    }
    private mutating func addGiftReaction() {
        let choices = ConversationLibrary.giftReactions(large: giftReactionAmount >= 500).shuffled(using: &random)
        guard let line = choices.first(where: { chatMemory.allows($0) }), let person = makePersona() else { return }
        chatMemory.accept(line)
        append(.init(name: person.name, avatar: person.avatar, color: person.color, text: line, replyTo: giftReactionName))
    }
    private mutating func scheduleChat() {
        let base = 60 / settings.messagesPerMinute
        nextChat = episode.isEmpty ? max(0.8, base * (0.65 + random.unit() * 0.9)) : max(1.1, base * (0.5 + random.unit() * 0.6))
        if eventBudget > 0 { nextChat = 1.5 + random.unit() * 2.2 }
        if activeScenario == .study && context == nil { nextChat *= 1.5 }
    }
    private mutating func scheduleDonation() {
        nextDonation = settings.donationsPerMinute > 0 ? (60 / settings.donationsPerMinute) * (0.75 + random.unit() * 0.6) : .infinity
    }
    private mutating func append(_ message: ChatMessage) {
        messages.append(message)
        if messages.count > 160 { messages.removeFirst(messages.count - 160) }
    }
    private mutating func makePersona() -> Persona? {
        for _ in 0..<300 {
            let a = ConversationLibrary.nameStarts[random.index(ConversationLibrary.nameStarts.count)]
            let b = ConversationLibrary.nameEnds[random.index(ConversationLibrary.nameEnds.count)]
            let n = random.index(100)
            let name: String
            switch random.index(5) {
            case 0: name = a + "_" + b + (n < 40 ? "" : String(n))
            case 1: name = a + b.prefix(1).uppercased() + b.dropFirst() + String(n)
            case 2: name = ["sam", "jamie", "alex", "milo", "jules", "riley", "kai", "taylor", "leo", "drew", "erin", "max", "ash", "jordan", "remy", "charlie"][random.index(16)] + "_" + b + (n < 60 ? "" : String(n))
            case 3: name = a + "." + b + String(n)
            default: name = a + b + (n == 0 ? "" : String(n))
            }
            if usedNames.insert(name.lowercased()).inserted {
                return Persona(name: name, avatar: name.prefix(1).uppercased() + b.prefix(1).uppercased(), color: random.index(6), personality: Personality.allCases[random.index(4)])
            }
        }
        return nil
    }
    private mutating func addReaction() {
        var selected: String?
        var fromLocal = false
        while !localMessages.isEmpty && selected == nil {
            let line = localMessages.removeFirst()
            if chatMemory.accept(line) { selected = line; fromLocal = true; replyName = nil; episode = [] }
        }
        if selected == nil {
            if episode.isEmpty {
                let event = eventBudget > 0 ? context : nil
                let specific = ConversationLibrary.threads(event: event, scenario: activeScenario)
                    .filter { !usedThreads.contains($0.id) }.shuffled(using: &random)
                let ambient = event == nil ? [] : ConversationLibrary.threads(event: nil, scenario: activeScenario)
                    .filter { !usedThreads.contains($0.id) }.shuffled(using: &random)
                if let thread = (specific + ambient).first(where: { $0.lines.contains(where: { chatMemory.allows($0) }) }) {
                    usedThreads.insert(thread.id)
                    episode = cameraContextActive && specific.contains(where: { $0.id == thread.id }) ? Array(thread.lines.prefix(max(1, eventBudget))) : thread.lines
                    replyName = nil
                }
            }
            while !episode.isEmpty && selected == nil {
                let line = episode.removeFirst()
                if chatMemory.accept(line) { selected = line }
            }
        }
        guard let line = selected, let person = makePersona() else { contentExhausted = true; return }
        contentExhausted = false
        uniqueMessages += 1
        if fromLocal { acceptedLocalMessages += 1 }
        append(.init(name: person.name, avatar: person.avatar, color: person.color, text: line, replyTo: replyName))
        replyName = episode.isEmpty ? nil : person.name
        eventBudget = max(0, eventBudget - 1)
    }
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
