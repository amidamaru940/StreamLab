import Foundation

/// How one participant writes and pays attention. Stable for the participant's lifetime (A5).
struct Voice: Codable, Equatable {
    /// Probability of writing in lowercase without a final full stop.
    var casual: Double
    /// 0 = happy to write longer lines, 1 = mostly short replies.
    var brevity: Double
    /// Relative speaking weight; lurkers are well below 1.
    var chattiness: Double
    /// Chance this person notices a host message or on-screen moment at all.
    var attention: Double
    /// Seconds before they look at chat after something happens (median).
    var noticeLag: Double
    var readingWordsPerSecond: Double
    var typingCharactersPerSecond: Double
    /// Tendency to ask the host things.
    var curiosity: Double
    /// Rough generosity; used only by the app's gift planner, never by the text writer.
    var generosity: Double

    var summary: String {
        var parts: [String] = []
        parts.append(brevity > 0.66 ? "very short messages" : brevity < 0.33 ? "full sentences" : "short messages")
        parts.append(casual > 0.6 ? "lowercase, casual" : "normal capitalisation")
        if curiosity > 0.6 { parts.append("asks questions") }
        return parts.joined(separator: ", ")
    }
}

enum Presence: String, Codable { case away, present }

/// A persistent member of the fictional community (A1). The participant ID is the identity;
/// the nickname is just how they appear.
struct Participant: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let avatar: String
    let color: Int
    let personality: Personality
    let voice: Voice
    /// Regulars return often; others drop in occasionally.
    let regular: Bool
    var presence: Presence = .away
    var joinedAt: Double = 0
    var leftAt: Double = -1000
    var lastSpokeAt: Double = -1000
    var messages = 0
    var sessionTips = 0
    var sessionTipTotal = 0
    /// Tips from earlier sessions that really happened in this app on this phone.
    var pastTips = 0
    var pastTipTotal = 0
    var sessionsSeen = 0
    /// Earlier streams in which this person actually wrote something.
    var streamsChatted = 0
    /// Something this person asked and may still be waiting on.
    var openQuestion: String?
    var openQuestionAt: Double = -1000

    var present: Bool { presence == .present }
    private enum CodingKeys: String, CodingKey { case id, name, avatar, color, personality, voice, regular, pastTips, pastTipTotal, sessionsSeen, streamsChatted }
}

/// Stored between launches. Only identities and gift history that actually happened in the app.
struct CommunitySnapshot: Codable {
    var version = 1
    var people: [Participant]
}

struct Audience {
    private(set) var people: [Participant] = []
    private var usedNames: Set<String> = []
    private var nextID = 1

    init(restoring saved: [Participant]? = nil, using random: inout StreamRandom) {
        if let saved, !saved.isEmpty {
            for var person in saved.prefix(220) where !person.name.isEmpty && usedNames.insert(person.name.lowercased()).inserted {
                person.presence = .away
                person.sessionsSeen += 1
                people.append(person)
                nextID = max(nextID, person.id + 1)
            }
        }
        let wanted = max(0, 70 - people.count)
        for index in 0..<wanted { _ = add(regular: index < 46, using: &random) }
    }

    var presentIDs: [Int] { people.filter(\.present).map(\.id) }
    var presentCount: Int { people.reduce(0) { $0 + ($1.present ? 1 : 0) } }
    subscript(id: Int) -> Participant? {
        guard let index = index(of: id) else { return nil }
        return people[index]
    }
    func index(of id: Int) -> Int? { people.firstIndex { $0.id == id } }
    mutating func update(_ id: Int, _ change: (inout Participant) -> Void) {
        guard let index = index(of: id) else { return }
        change(&people[index])
    }

    @discardableResult mutating func add(regular: Bool, using random: inout StreamRandom) -> Int? {
        guard let identity = Self.makeIdentity(avoiding: &usedNames, using: &random) else { return nil }
        let personality = Personality.allCases[random.index(Personality.allCases.count)]
        let lurker = random.unit() < 0.3
        let voice = Voice(
            casual: random.unit() < 0.55 ? 0.6 + random.unit() * 0.4 : random.unit() * 0.4,
            brevity: personality == .analyst ? random.unit() * 0.5 : 0.25 + random.unit() * 0.75,
            chattiness: lurker ? 0.15 + random.unit() * 0.3 : 0.6 + random.unit() * 1.8,
            attention: 0.3 + random.unit() * 0.6,
            noticeLag: 0.8 + random.unit() * 3.5,
            readingWordsPerSecond: 3 + random.unit() * 3,
            typingCharactersPerSecond: 3.5 + random.unit() * 5.5,
            curiosity: random.unit(),
            generosity: random.unit() * random.unit())
        let person = Participant(id: nextID, name: identity.name, avatar: identity.avatar, color: random.index(6), personality: personality, voice: voice, regular: regular)
        nextID += 1
        people.append(person)
        return person.id
    }

    /// Picks someone present who is not among `excluding`. Recent speakers and lurkers are less likely.
    func pickSpeaker(now: Double, excluding: Set<Int> = [], using random: inout StreamRandom, weight: (Participant) -> Double = { _ in 1 }) -> Int? {
        var total = 0.0
        var candidates: [(Int, Double)] = []
        for person in people where person.present && !excluding.contains(person.id) {
            let since = now - person.lastSpokeAt
            let recency = since < 4 ? 0.05 : since < 15 ? 0.4 : 1
            let w = person.voice.chattiness * recency * weight(person)
            guard w > 0 else { continue }
            total += w; candidates.append((person.id, w))
        }
        guard total > 0 else { return nil }
        var roll = random.unit() * total
        for (id, w) in candidates { roll -= w; if roll < 0 { return id } }
        return candidates.last?.0
    }

    /// Moves people in and out so that roughly `target` chatters are present.
    /// Returns arrivals and departures so the engine can decide whether anyone says hello or goodbye.
    mutating func balance(target: Int, now: Double, using random: inout StreamRandom) -> (joined: [Int], left: [Int]) {
        var joined: [Int] = [], left: [Int] = []
        let count = presentCount
        if count < target {
            let away = people.indices.filter { !people[$0].present && now - people[$0].leftAt > 90 }
            if !away.isEmpty && random.unit() < 0.93 {
                let weights = away.map { people[$0].regular ? 3.0 : 1.0 }
                var roll = random.unit() * weights.reduce(0, +)
                var chosen = away[0]
                for (i, w) in zip(away, weights) { roll -= w; if roll < 0 { chosen = i; break } }
                people[chosen].presence = .present; people[chosen].joinedAt = now
                joined.append(people[chosen].id)
            } else if let id = add(regular: false, using: &random) {
                update(id) { $0.presence = .present; $0.joinedAt = now }
                joined.append(id)
            }
        } else if count > target + 1 || (count > 3 && random.unit() < 0.25) {
            let candidates = people.indices.filter { people[$0].present && now - people[$0].joinedAt > 120 && now - people[$0].lastSpokeAt > 10 }
            if let i = candidates.isEmpty ? nil : candidates[random.index(candidates.count)] {
                people[i].presence = .away; people[i].leftAt = now; people[i].openQuestion = nil
                left.append(people[i].id)
            }
        }
        return (joined, left)
    }

    /// Fills the room at the start without anyone announcing themselves.
    mutating func seat(_ count: Int, now: Double, using random: inout StreamRandom) {
        var order = people.indices.filter { !people[$0].present }.shuffled(using: &random)
        order.sort { people[$0].regular && !people[$1].regular }
        for i in order.prefix(count) { people[i].presence = .present; people[i].joinedAt = now - random.unit() * 600 }
    }

    var snapshot: CommunitySnapshot {
        var stored = people.sorted { ($0.pastTipTotal + $0.sessionTipTotal, $0.messages) > ($1.pastTipTotal + $1.sessionTipTotal, $1.messages) }
        stored = Array(stored.prefix(160))
        for i in stored.indices {
            stored[i].pastTips += stored[i].sessionTips; stored[i].pastTipTotal += stored[i].sessionTipTotal
            if stored[i].messages > 0 { stored[i].streamsChatted += 1 }
            stored[i].sessionTips = 0; stored[i].sessionTipTotal = 0
        }
        return CommunitySnapshot(people: stored.sorted { $0.id < $1.id })
    }

    private static func makeIdentity(avoiding used: inout Set<String>, using random: inout StreamRandom) -> (name: String, avatar: String)? {
        let starts = ConversationLibrary.nameStarts, ends = ConversationLibrary.nameEnds
        for _ in 0..<300 {
            let a = starts[random.index(starts.count)], b = ends[random.index(ends.count)]
            let n = random.index(100)
            let name: String
            switch random.index(6) {
            case 0: name = a + "_" + b + (n < 40 ? "" : String(n))
            case 1: name = a + b.prefix(1).uppercased() + b.dropFirst() + String(n)
            case 2: name = ["sam", "jamie", "alex", "milo", "jules", "riley", "kai", "taylor", "leo", "drew", "erin", "max", "ash", "jordan", "remy", "charlie", "nico", "bea", "ollie", "rae"][random.index(20)] + "_" + b + (n < 60 ? "" : String(n))
            case 3: name = a + "." + b + String(n)
            case 4: name = b + "_" + ["irl", "tv", "xo", "zz", "lol", "jr"][random.index(6)]
            default: name = a + b + (n == 0 ? "" : String(n))
            }
            if used.insert(name.lowercased()).inserted {
                return (name, name.prefix(1).uppercased() + b.prefix(1).uppercased())
            }
        }
        return nil
    }
}
