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
    case expired, staleContext, duplicate, speakerLeft, queueFull, noModelText
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
    /// Only worth posting if the model wrote it; otherwise the person simply does not reply.
    var requiresModel = false
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
    /// What kind of yes/no question it is decides what a sensible short answer looks like.
    enum YesNoForm: Equatable { case advice, check, presence, general }
    /// Statements are not all opinions: most host lines are filler, news or announcements.
    enum StatementForm: Equatable { case filler, opinion, news, welcome, event }
    enum Kind: Equatable {
        case greeting, howAreYou, thanks, bye
        case yesNoQuestion(YesNoForm), openQuestion
        case choice(String, String)
        case statement(StatementForm)
        case nonEnglish
    }
    let kind: Kind
    let mentions: [String]
    /// Content words for matching a library topic; generic words are excluded.
    let keywords: Set<String>
    let event: StreamEvent?
    /// The host text without @mentions, lowercased.
    let body: String

    var isQuestion: Bool {
        switch kind {
        case .yesNoQuestion, .openQuestion, .choice, .howAreYou: return true
        default: return false
        }
    }

    static let genericWords: Set<String> = ["favorite", "favourite", "take", "first", "night", "late", "time", "today", "day", "live", "working", "enough", "people", "ready", "opinion", "kind", "warm", "goal", "fun", "free", "phone", "read", "good", "best", "like", "new", "last", "next", "much", "many", "thing", "things", "stuff", "really", "ever", "still", "right", "now", "get", "got", "make", "made", "play", "watch", "use", "you", "your", "what", "how", "why", "who", "where", "when", "which", "is", "are", "do", "does", "did", "the", "a", "an", "and", "or", "to", "of", "in", "on", "at", "for", "with", "it", "this", "that", "i", "me", "my", "we", "us", "our", "chat", "guys", "everyone", "anyone", "all", "should", "would", "could", "can", "will", "be", "have", "has", "was", "were", "am", "so", "just", "about", "think", "know", "want", "need", "tonight", "morning", "evening"]
    private static let greetWords: Set<String> = ["hi", "hello", "hey", "hiya", "yo", "sup", "heya", "howdy", "evening", "morning", "hii", "heyo"]
    private static let fillerWords: Set<String> = ["lol", "lmao", "lmfao", "haha", "hahaha", "hah", "nice", "gg", "ok", "okay", "k", "yeah", "yep", "yes", "no", "nope", "wow", "damn", "oof", "rip", "true", "same", "hmm", "hm", "omg", "bruh", "sheesh", "cool", "yay", "ayy", "welp", "huh", "oh", "ah", "lets", "go", "pog"]
    private static let openers: Set<String> = ["what", "why", "how", "who", "where", "which", "when"]
    private static let yesNoStarts: Set<String> = ["do", "does", "did", "is", "are", "was", "were", "can", "could", "should", "would", "will", "have", "has", "anyone", "any", "anybody", "shall", "am", "you", "u", "isn't", "aren't", "don't", "didn't", "can't"]
    private static let leadIns: Set<String> = ["hey", "hi", "hello", "yo", "ok", "okay", "so", "chat", "guys", "everyone", "all", "alright", "quick", "question", "real", "btw", "um", "hmm", "well", "oh", "random", "serious", "y'all", "folks", "friends"]

    static func parse(_ raw: String) -> HostIntent {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let mentions = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).filter { $0.hasPrefix("@") && $0.count > 1 }
            .map { String($0.dropFirst()).trimmingCharacters(in: .punctuationCharacters).lowercased() }
        // @mentions are addressed people, not part of what is being said.
        var body = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).filter { !$0.hasPrefix("@") }.joined(separator: " ").lowercased()
            .replacingOccurrences(of: "’", with: "'")
        for (short, long) in [("what's", "what is"), ("how's", "how is"), ("who's", "who is"), ("where's", "where is"), ("when's", "when is"), ("wanna", "want to")] {
            body = body.replacingOccurrences(of: short, with: long)
        }
        let words = body.split { !$0.isLetter && !$0.isNumber && $0 != "'" }.map(String.init)
        let letters = body.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        let latin = letters.filter { $0.isASCII }.count
        if letters.count >= 3 && Double(latin) / Double(letters.count) < 0.6 {
            return HostIntent(kind: .nonEnglish, mentions: mentions, keywords: [], event: detectEvent(body: body, words: words), body: body)
        }
        let event = detectEvent(body: body, words: words)
        let keywords = Set(words).subtracting(genericWords)
        // Skip greetings and lead-ins such as "hey chat," to find how the sentence really starts.
        let core = Array(words.drop { leadIns.contains($0) || greetWords.contains($0) })
        let first = core.first ?? ""
        let second = core.count > 1 ? core[1] : ""
        let exclamation = (first == "what" && second == "a") || (first == "how" && ["cool", "nice", "funny", "great", "cute", "weird", "fun", "sad"].contains(second))
        let looksLikeQuestion = !exclamation && (body.contains("?") || openers.contains(first) || yesNoStarts.contains(first))
        let has = { (list: [String]) in list.contains { words.contains($0) } }
        let kind: Kind
        if looksLikeQuestion {
            if isHowAreYou(body) { kind = .howAreYou }
            else if let options = choice(in: body) { kind = .choice(options.0, options.1) }
            else if yesNoStarts.contains(first) { kind = .yesNoQuestion(yesNoForm(core: core, body: body)) }
            else { kind = .openQuestion }
        }
        else if has(["thanks", "thank", "ty", "thx", "tysm"]) { kind = .thanks }
        else if isGoodbye(body: body, words: words) { kind = .bye }
        else if let w = words.first, greetWords.contains(w), words.count <= 6, !words.contains("welcome") { kind = .greeting }
        else if words.first == "good" && words.count <= 5 && (words.contains("morning") || words.contains("evening") || words.contains("afternoon")) { kind = .greeting }
        else if words.contains("welcome") { kind = .statement(.welcome) }
        else if event != nil { kind = .statement(.event) }
        else if words.isEmpty || words.allSatisfy({ fillerWords.contains($0) }) || (words.count <= 2 && !body.contains(" i ")) { kind = .statement(.filler) }
        else if has(["think", "honestly", "better", "worse", "worst", "best", "overrated", "underrated", "prefer", "love", "hate", "opinion", "agree", "should", "favorite", "favourite"]) { kind = .statement(.opinion) }
        else { kind = .statement(.news) }
        return HostIntent(kind: kind, mentions: mentions, keywords: keywords, event: event, body: body)
    }

    private static func isHowAreYou(_ body: String) -> Bool {
        ["how are you", "how are y'all", "how are yall", "how is everyone", "how is chat", "how are we doing", "how are we feeling today", "how is your day", "how is your night", "how is your evening", "how was your day", "how is it going", "how are things", "how you doing", "how are you all"].contains { body.contains($0) }
            && !body.contains("how are you feeling about") && !body.contains("how are we feeling about")
    }
    private static func isGoodbye(body: String, words: [String]) -> Bool {
        ["good night", "goodnight", "night all", "night chat", "night everyone", "gotta go", "signing off", "ending the stream", "ending stream", "end the stream", "wrapping up", "that's it for today", "that's it for tonight", "see you tomorrow", "see you next time", "see ya", "bye"].contains { body.contains($0) }
            || words == ["gn"] || words == ["night"] || words.first == "bye"
    }
    private static func yesNoForm(core: [String], body: String) -> YesNoForm {
        let first = core.first ?? ""
        if ["should", "shall"].contains(first) || body.contains("should i") || body.contains("do i ") || body.contains("would it be") { return .advice }
        if ["can you hear", "can you see", "can y'all hear", "can everyone hear", "are we live", "is the audio", "is the sound", "is the mic", "is my mic", "is the stream", "is it lagging", "am i live", "is this working"].contains(where: body.contains) { return .check }
        if ["anyone", "anybody"].contains(first) && ["here", "around", "awake", "still", "watching"].contains(where: body.contains) || body.contains("is anyone here") || body.contains("who is here") { return .presence }
        return .general
    }

    /// "Tea or coffee?" → ("tea", "coffee"). Only short, clean options from a question are used.
    static func choice(in body: String) -> (String, String)? {
        guard body.contains("?"), let range = body.range(of: " or "), !body.contains("whether") else { return nil }
        let clauseBreak: Set<Character> = [",", ":", ";", "!", ".", "?"]
        let leftClause = body[..<range.lowerBound].split(omittingEmptySubsequences: false, whereSeparator: { clauseBreak.contains($0) }).last.map(String.init) ?? ""
        let rightClause = body[range.upperBound...].split(omittingEmptySubsequences: false, whereSeparator: { clauseBreak.contains($0) }).first.map(String.init) ?? ""
        let tokenize = { (s: String) in s.split { !$0.isLetter && !$0.isNumber && $0 != "'" && $0 != "-" }.map(String.init) }
        let fillerLeft: Set<String> = ["should", "i", "we", "do", "you", "prefer", "like", "want", "would", "rather", "play", "go", "with", "for", "the", "a", "an", "chat", "guys", "so", "ok", "okay", "which", "is", "it", "better", "more", "what", "pick", "team", "get", "have", "eat", "drink", "watch", "make", "choose", "either", "between", "are", "your", "my", "y'all", "to", "of"]
        let stopRight: Set<String> = ["in", "on", "at", "for", "to", "tonight", "today", "now", "later", "then", "first", "instead", "again", "this", "that", "what", "so", "something", "anything", "please", "chat", "guys", "lol", "or", "next", "tomorrow", "y'all", "with", "after", "before"]
        let banned: Set<String> = ["not", "no", "later", "less", "more", "so", "else", "what", "something", "anything", "whatever", "nothing", "both", "neither", "sooner", "never", "maybe", "it", "that", "this", "them", "me", "you"]
        var leftWords: [String] = []
        for word in tokenize(leftClause).reversed() { if fillerLeft.contains(word) || leftWords.count == 2 { break }; leftWords.insert(word, at: 0) }
        var rightWords: [String] = []
        for word in tokenize(rightClause) where !(rightWords.isEmpty && ["the", "a", "an", "team", "maybe"].contains(word)) { if stopRight.contains(word) || rightWords.count == 2 { break }; rightWords.append(word) }
        guard !leftWords.isEmpty, !rightWords.isEmpty else { return nil }
        let left = leftWords.joined(separator: " "), right = rightWords.joined(separator: " ")
        guard left != right, left.count <= 20, right.count <= 20, !banned.contains(left), !banned.contains(right),
              !banned.contains(leftWords.last ?? ""), !banned.contains(rightWords.last ?? "") else { return nil }
        return (left, right)
    }

    /// Only clear first-person announcements count. "who won?", "I almost won" or "they won" do not.
    private static func detectEvent(body: String, words: [String]) -> StreamEvent? {
        let negative = ["not", "never", "no", "didn't", "won't", "almost", "nearly", "could", "would", "should", "if", "не"].contains { words.contains($0) }
        let isQuestion = body.contains("?")
        if !negative && !isQuestion {
            for i in words.indices where words[i] == "won" {
                let before = i > 0 ? words[i - 1] : ""
                let before2 = i > 1 ? words[i - 2] : ""
                if i == 0 || ["i", "we"].contains(before) || (before == "just" && ["i", "we"].contains(before2)) || before == "finally" { return .win }
            }
            if words.contains("победа") || words.contains("выиграл") || words.contains("выиграла") { return .win }
        }
        if words.contains("brb") || body.contains("be right back") || body.contains("short break") || words.contains("перерыв") { return .breakTime }
        if words == ["back"] || words == ["wb"] || body.contains("i'm back") || body.contains("im back") || body.contains("i am back") || body.contains("we're back") || body.contains("back now") || words.contains("вернулся") || words.contains("вернулась") { return .returnLive }
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

    mutating func record(_ message: PlannedMessage, at time: Double, parentShownAt: Double?) {
        delivered[message.source, default: 0] += 1
        let delay = time - message.causeTime
        if message.source == .hostReply { Self.keep(&hostReplyDelays, delay) }
        if message.source == .eventReaction { Self.keep(&reactionDelays, delay) }
        Self.keep(&lateness, time - message.due)
        if message.writtenByModel { modelDelivered += 1 }
        // Anything that answers something must not appear within a second of what it answers.
        if let parent = parentShownAt, time - parent < 1 { sameUpdateReplies += 1 }
        else if parentShownAt == nil && (message.source == .hostReply || message.source == .eventReaction || message.source == .giftReaction) && delay < 1 { sameUpdateReplies += 1 }
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
    /// Short notes on what really happened earlier in this stream (A3), oldest first.
    var memory: [String] = []
    /// Ask for one fresh viewer question with a few different answers (a new topic beyond the library).
    var topicWanted = false
}

/// A viewer question and independent answers written by the model; the app decides who posts them and when.
struct GeneratedTopic: Equatable {
    let question: String
    let answers: [String]
}

struct WritingResult {
    var slotTexts: [UUID: String]
    var ambient: [String]
    var topic: GeneratedTopic? = nil

    /// Reads the model's structured JSON. Unknown keys are ignored; oversized or malformed output is rejected.
    static func parse(_ json: String, request: WritingRequest) -> WritingResult? {
        guard json.utf8.count <= 12000, let start = json.firstIndex(of: "{"), let end = json.lastIndex(of: "}"), start <= end,
              let object = try? JSONSerialization.jsonObject(with: Data(json[start...end].utf8)) as? [String: Any] else { return nil }
        var texts: [UUID: String] = [:]
        for (index, slot) in request.slots.enumerated() {
            if let value = object["line\(index + 1)"] as? String { texts[slot.id] = value }
        }
        let ambient = (object["ambient"] as? [Any])?.compactMap { $0 as? String } ?? []
        var topic: GeneratedTopic?
        if request.topicWanted, let question = object["topic_question"] as? String,
           let answers = (object["topic_answers"] as? [Any])?.compactMap({ $0 as? String }), !answers.isEmpty {
            topic = GeneratedTopic(question: question, answers: answers)
        }
        return WritingResult(slotTexts: texts, ambient: ambient, topic: topic)
    }
}

/// Viewer-started "X or Y?" polls (E6). Answers are composed from the two options, so they always
/// refer to what was asked; tallies in the asker's follow-up reflect the answers actually planned.
enum ChoiceDebates {
    struct Pair { let a: String; let b: String; let scenes: [String] }
    static let pairs: [Pair] = [
        Pair(a: "cats", b: "dogs", scenes: ["any"]), Pair(a: "sweet", b: "salty", scenes: ["any"]),
        Pair(a: "summer", b: "winter", scenes: ["any"]), Pair(a: "morning", b: "night", scenes: ["any"]),
        Pair(a: "pizza", b: "burgers", scenes: ["any"]), Pair(a: "books", b: "movies", scenes: ["any"]),
        Pair(a: "beach", b: "mountains", scenes: ["any"]), Pair(a: "sunrise", b: "sunset", scenes: ["any"]),
        Pair(a: "pancakes", b: "waffles", scenes: ["any"]), Pair(a: "chocolate", b: "vanilla", scenes: ["any"]),
        Pair(a: "rain", b: "snow", scenes: ["any"]), Pair(a: "city", b: "countryside", scenes: ["any"]),
        Pair(a: "calling", b: "texting", scenes: ["any"]), Pair(a: "window seat", b: "aisle seat", scenes: ["any"]),
        Pair(a: "headphones", b: "speakers", scenes: ["any"]), Pair(a: "fries", b: "onion rings", scenes: ["any"]),
        Pair(a: "cake", b: "pie", scenes: ["any"]), Pair(a: "hoodie", b: "jacket", scenes: ["any"]),
        Pair(a: "cereal", b: "toast", scenes: ["any"]), Pair(a: "hot coffee", b: "iced coffee", scenes: ["any"]),
        Pair(a: "bath", b: "shower", scenes: ["any"]), Pair(a: "stairs", b: "elevator", scenes: ["any"]),
        Pair(a: "sci-fi", b: "fantasy", scenes: ["any"]), Pair(a: "horror", b: "comedy", scenes: ["any"]),
        Pair(a: "podcasts", b: "music", scenes: ["any"]), Pair(a: "early bird", b: "night owl", scenes: ["any"]),
        Pair(a: "pineapple on pizza", b: "no pineapple", scenes: ["any"]), Pair(a: "ketchup", b: "mayo", scenes: ["any"]),
        Pair(a: "paper books", b: "ebooks", scenes: ["any"]), Pair(a: "spring", b: "autumn", scenes: ["any"]),
        Pair(a: "big breakfast", b: "skip breakfast", scenes: ["any"]), Pair(a: "tacos", b: "burritos", scenes: ["any"]),
        Pair(a: "soup", b: "salad", scenes: ["any"]), Pair(a: "bike", b: "walk", scenes: ["any"]),
        Pair(a: "nap", b: "coffee", scenes: ["any"]), Pair(a: "board games", b: "card games", scenes: ["any"]),
        Pair(a: "controller", b: "keyboard", scenes: ["Late night gaming"]), Pair(a: "story mode", b: "multiplayer", scenes: ["Late night gaming"]),
        Pair(a: "easy mode", b: "hard mode", scenes: ["Late night gaming", "One more attempt"]), Pair(a: "headset", b: "speakers on", scenes: ["Late night gaming"]),
        Pair(a: "stealth", b: "loud", scenes: ["Late night gaming"]), Pair(a: "open world", b: "linear", scenes: ["Late night gaming"]),
        Pair(a: "quick retry", b: "short break", scenes: ["One more attempt"]), Pair(a: "practice mode", b: "full runs", scenes: ["One more attempt"]),
        Pair(a: "slow and clean", b: "fast and messy", scenes: ["One more attempt", "Music & practice"]),
        Pair(a: "spicy", b: "mild", scenes: ["Cooking & food"]), Pair(a: "pasta", b: "rice", scenes: ["Cooking & food"]),
        Pair(a: "cooking", b: "takeout", scenes: ["Cooking & food"]), Pair(a: "garlic", b: "onion", scenes: ["Cooking & food"]),
        Pair(a: "crispy", b: "soft", scenes: ["Cooking & food"]), Pair(a: "gas stove", b: "electric", scenes: ["Cooking & food"]),
        Pair(a: "sunny walk", b: "rainy walk", scenes: ["IRL & outdoors"]), Pair(a: "parks", b: "streets", scenes: ["IRL & outdoors"]),
        Pair(a: "headphones outside", b: "no headphones", scenes: ["IRL & outdoors"]), Pair(a: "map", b: "wander", scenes: ["IRL & outdoors"]),
        Pair(a: "guitar", b: "piano", scenes: ["Music & practice"]), Pair(a: "metronome", b: "no metronome", scenes: ["Music & practice"]),
        Pair(a: "learn by ear", b: "sheet music", scenes: ["Music & practice"]), Pair(a: "scales first", b: "songs first", scenes: ["Music & practice"]),
        Pair(a: "lofi", b: "silence", scenes: ["Focus & study"]), Pair(a: "pen", b: "pencil", scenes: ["Focus & study"]),
        Pair(a: "paper notes", b: "laptop notes", scenes: ["Focus & study"]), Pair(a: "library", b: "cafe", scenes: ["Focus & study"]),
        Pair(a: "long sessions", b: "short sprints", scenes: ["Focus & study"]), Pair(a: "desk", b: "couch", scenes: ["Focus & study"])
    ]
    static let openers = ["%a or %b?", "%a or %b, go", "chat: %a or %b", "important question: %a or %b", "%a or %b? need to settle something", "quick poll, %a or %b", "ok %a or %b"]
    /// Short forms may recur between people; longer forms are used once per session.
    static let answers = ["%x", "%x", "%x obviously", "team %x", "%x tbh", "%x, not even close", "has to be %x", "%x every single time",
                          "depends on the day but %x", "i used to say %y but %x now", "%x and i'm not explaining", "%x, %y is overrated",
                          "%x. this isn't a debate", "honestly %x", "%x for me", "always %x", "%x, easy"]
    static let neutral = ["both", "neither", "both??", "depends tbh", "can't choose"]
    static let tallies = ["%w winning so far", "ok %w it is", "%w gang showing up", "%l people are quiet tonight", "split chat, love it", "wow chat really likes %w"]
}
