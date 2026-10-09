import Foundation

// Engine checks for StreamLab v6. Some v5 checks were intentionally changed:
// nicknames now return (persistent participants, A1), round tip amounts may repeat (B4),
// short reactions like "lol" may repeat (A4), and nothing reacts in the same update as its cause (A6).

setvbuf(stdout, nil, _IOLBF, 0)
var checks = 0
func check(_ value: @autoclosure () -> Bool, _ name: String) {
    guard value() else { fatalError("FAIL: \(name)") }
    checks += 1; print("PASS: \(name)")
}
func advance(_ sim: inout Simulation, seconds: Double) {
    for _ in 0..<Int(seconds * 4) { sim.tick(0.25) }
}
func viewerMessages(_ sim: Simulation, after time: Double) -> [ChatMessage] {
    sim.messages.filter { !$0.isHost && !$0.isDonation && $0.postedAt > time }
}
var quiet = Settings(); quiet.donationsPerMinute = 0; quiet.localWriting = false

// MARK: Basics and pause
var sim = Simulation(settings: quiet, seed: 42)
check(!sim.messages.isEmpty && sim.activeScenario == .cozy, "Automatic scene starts with a room already talking, without inventing camera activity")
check(Scenario.allCases.count == 8, "Eight scenarios including automatic selection")
check(sim.presentChatters >= 4 && sim.presentChatters <= 45, "Active chatters follow the viewer count")
let beforeWin = sim.messages.count
sim.trigger(.win)
check(sim.context == .win && sim.messages.count == beforeWin, "Manual Win posts nothing synchronously")
let winAt = sim.now
advance(&sim, seconds: 25)
let winReactions = sim.messages.filter { $0.source == .eventReaction && $0.postedAt > winAt }
check(!winReactions.isEmpty && winReactions.allSatisfy { $0.postedAt - winAt >= 1.2 }, "Win reactions arrive after noticing and typing time")
let winTimes = winReactions.map(\.postedAt)
check(winTimes.count < 3 || (winTimes.max()! - winTimes.min()! >= 2), "Reactions are spread out rather than landing together")
sim.donate()
let freeze = (sim.elapsed, sim.messages.count, sim.total, sim.donation?.id, sim.donationProgress)
sim.pause(); advance(&sim, seconds: 30); sim.donate(); sim.trigger(.fail); sim.send("test")
check(sim.elapsed == freeze.0 && sim.messages.count == freeze.1 && sim.total == freeze.2 && sim.donation?.id == freeze.3 && sim.donationProgress == freeze.4, "Pause freezes engine, input, tips and progress")
sim.togglePause()
let resumeCount = sim.messages.count
sim.tick(0.25); sim.tick(0.25); sim.tick(0.25); sim.tick(0.25)
check(sim.messages.count - resumeCount <= 4, "Resume does not dump a backlog of queued reactions")
advance(&sim, seconds: 15)
check(sim.donation == nil && sim.elapsed > freeze.0, "Resume expires the longer tip banner")
advance(&sim, seconds: 30)
check(sim.context == nil && sim.total == freeze.2, "Contexts expire; zero tip pace stays off")
let clock = sim.elapsed; sim.tick(1000)
check(sim.elapsed == clock + 1, "No long catch-up after suspension")
let invalidClock = sim.elapsed; sim.tick(.nan); sim.tick(-1); sim.tick(.infinity)
check(sim.elapsed == invalidClock, "Invalid time values are ignored")

// MARK: Gift banners and queue
var queue = Simulation(settings: quiet, seed: 6)
queue.donate(); let first = queue.donation!.id; let duration = queue.donation!.displayDuration
check(duration >= 7 && duration <= 11.5, "Default notifications are longer than v4")
queue.donate(); let second = queue.donationQueue[0].id
advance(&queue, seconds: 6)
check(queue.donation?.id == first, "Tip remains visible after six seconds")
while queue.donation?.id == first { queue.tick(0.25) }
check(queue.donation == nil, "Small quiet gap between banners")
queue.donate(); advance(&queue, seconds: 1)
check(queue.donation?.id == second, "Arriving during the gap cannot jump the FIFO queue")
for _ in 0..<20 { queue.donate() }
let totalAtCapacity = queue.total
check(queue.donationQueue.count == 12 && !queue.donate() && queue.total == totalAtCapacity, "Queue has backpressure without false totals")
let slow = Simulation(seed: 72)
check(slow.nextDonation >= 52 && slow.nextDonation <= 96, "Default tips keep the slightly slower irregular timing")
var fixed = quiet; fixed.minAmount = 500; fixed.maxAmount = 500; fixed.tipDuration = 9
var fixedSim = Simulation(settings: fixed, seed: 1); fixedSim.donate()
check(fixedSim.donation?.amount == 500 && fixedSim.donation!.displayDuration >= 10, "Custom amount and notification time apply")

// MARK: Text memory and content
var memory = TextMemory()
check(memory.accept("The timing was perfect."), "New complete line is accepted")
check(!memory.accept("the timing was perfect!!! 😂"), "Punctuation, case and emoji cannot disguise a repeat")
check(memory.accept("I nearly dropped my tea laughing at that."), "Different topic accepted")
check(!memory.accept("I nearly dropped my tea while laughing at that!"), "Close rewording of a recent line is rejected")
check(!TextMemory.valid("As an AI language model, I cannot watch."), "Model boilerplate rejected")
check(!TextMemory.valid("go to https://example.com") && !TextMemory.valid("Visit HTTPS://example.com"), "Links rejected in generated chat")
check(!TextMemory.valid("first line\nsecond line") && !TextMemory.valid("first\rsecond"), "Multiline generated output rejected")
let topics = Simulation.allTopics
check(Set(topics.map(\.id)).count == topics.count, "Conversation topic identities are unique")
check(topics.allSatisfy { !$0.openers.isEmpty && !$0.answers.isEmpty }, "Every topic has an opener and at least one answer")
var allLines: [String] = ChatContent.thanksReplies
for topic in topics { allLines += topic.openers; allLines += topic.answers; allLines += topic.followUps }
let pools: [[String: [String]]] = [ChatContent.short, ChatContent.events, ChatContent.hostReplies, ChatContent.viewerToHost, ChatContent.presence, ChatContent.tipNotes, ChatContent.giftReactions]
for pool in pools { for lines in pool.values { allLines += lines } }
// Single emoji or "W"/"F" are normal chat; the two-character minimum applies to model output.
let invalid = allLines.filter { !(TextMemory.valid($0, maxLength: 140) || ($0.count == 1 && !$0.contains("<"))) || $0.contains("$") }
if !invalid.isEmpty { print("Invalid lines: \(invalid.prefix(5))") }
check(invalid.isEmpty, "All authored lines are valid single chat lines without amounts")
for scene in Scenario.allCases where scene != .automatic {
    check(topics.filter { $0.scenes.contains(scene.rawValue) }.count >= 5, "Scene has its own topics: \(scene.rawValue)")
}
for event in StreamEvent.allCases {
    check((ChatContent.events[event.rawValue]?.count ?? 0) >= 8 && (ChatContent.events[event.rawValue + ".quick"]?.count ?? 0) >= 5, "Reactions exist for \(event.rawValue)")
}
print("Authored lines: \(allLines.count) across \(topics.count) topics")

// MARK: Host question: delayed, addressed, partial, parallel
var talk = Simulation(settings: quiet, seed: 2024)
advance(&talk, seconds: 10)
let countBefore = talk.messages.count
talk.send("Tea or coffee?")
let hostID = talk.messages.last!.id
let askedAt = talk.now
check(talk.messages.count == countBefore + 1 && talk.messages.last!.isHost, "Host question appears alone in its update")
advance(&talk, seconds: 70)
let replies = talk.messages.filter { $0.source == .hostReply && $0.postedAt > askedAt }
check(!replies.isEmpty && replies.allSatisfy { $0.postedAt - askedAt >= 1.3 && $0.replyToHost }, "Replies are addressed to the host and take reading and typing time")
check(replies.count < talk.presentChatters, "Not everyone in chat answers")
check(replies.contains { $0.text.lowercased().contains("tea") || $0.text.lowercased().contains("coffee") }, "Replies refer to the actual options in the question")
check(Set(replies.compactMap(\.participantID)).count == replies.count, "Each reply comes from a different person")
let interleaved = talk.messages.filter { $0.postedAt > askedAt && $0.source != .hostReply && !$0.isHost }
check(!interleaved.isEmpty, "Other conversation continues alongside the question")
check(talk.metrics.sameUpdateReplies == 0, "No reply lands within one second of its cause")
_ = hostID

let hostQuestions = ["What should I eat tonight?", "Do you like rainy days?", "Should I stream tomorrow?", "Pizza or pasta?", "How are you all doing?",
    "What are you all drinking?", "Cats or dogs?", "Anyone here?", "Can you hear me okay?", "What music are you listening to lately?",
    "Should I start a new game?", "Morning or night person?", "What's everyone snacking on?", "Do you play any instruments?", "Where would you travel next?",
    "Is anyone still at work?", "What's your comfort food?", "Sweet or salty?", "How was your day?", "Do you cook much?",
    "Should I get coffee?", "What time is it for you?", "Summer or winter?", "Are you watching anything good?", "What's the weather like where you are?",
    "Any weekend plans?", "Books or movies?", "Do you have pets?", "What did you have for dinner?", "Should I take a break soon?",
    "Tea or coffee?", "How long have you been up?", "What's your favorite season?", "Do you like spicy food?", "Beach or mountains?",
    "What are you working on today?", "Can you see the screen fine?", "Anyone else tired?", "What should I name my plant?", "Early bird or night owl?"]
// Delay distribution across many questions (hypotheses, measured not asserted as targets).
var delays: [Double] = []
var unanswered = 0
for seed in 0..<40 {
    var s = Simulation(settings: quiet, seed: UInt64(5000 + seed))
    advance(&s, seconds: 5)
    s.send(hostQuestions[seed]); let at = s.now
    advance(&s, seconds: 60)
    let r = s.messages.filter { $0.source == .hostReply && $0.postedAt > at }.map { $0.postedAt - at }
    if r.isEmpty { unanswered += 1 }
    delays += r
}
let sortedDelays = delays.sorted()
let medianDelay = sortedDelays[sortedDelays.count / 2], fastest = sortedDelays.first!, p90 = sortedDelays[Int(Double(sortedDelays.count) * 0.9)]
print(String(format: "Host reply delays, 40 different questions: n=%d fastest %.1fs median %.1fs p90 %.1fs; unanswered %d", delays.count, fastest, medianDelay, p90, unanswered))
check(fastest >= 1.3 && medianDelay >= 3 && medianDelay <= 16, "Typical replies arrive after a human-like pause")
check(unanswered <= 10, "Most questions get some answer, a few do not")

// MARK: Viewer topics keep authors and addressees
var topicSim = Simulation(settings: quiet, seed: 77)
advance(&topicSim, seconds: 240)
let byID = Dictionary(topicSim.messages.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
let answers = topicSim.messages.filter { $0.source == .topicAnswer }
check(!answers.isEmpty, "Viewers answer each other's questions")
var addressOK = true
for answer in answers {
    guard let target = answer.replyTo else { addressOK = false; continue }
    if let opener = topicSim.messages.last(where: { $0.source == .topicOpener && $0.name == target && $0.postedAt <= answer.postedAt }) {
        if answer.postedAt - opener.postedAt < (Simulation.isShort(answer.text) ? 1.2 : 2) || opener.participantID == answer.participantID { addressOK = false }
    }
}
check(addressOK, "Answers name the person who asked, arrive later and never come from the asker")
let followUps = topicSim.messages.filter { $0.source == .topicFollowUp }
check(followUps.allSatisfy { f in topicSim.messages.contains { $0.source == .topicOpener && $0.participantID == f.participantID && $0.postedAt < f.postedAt } }, "Follow-ups come from the same person who opened the topic")
_ = byID

// MARK: Moments: stale reactions are cancelled
var moments = Simulation(settings: quiet, seed: 9)
advance(&moments, seconds: 5)
moments.trigger(.win)
let pendingWin = moments.pending.filter { $0.source == .eventReaction }.count
let droppedBefore = moments.metrics.dropped[.staleContext] ?? 0
moments.trigger(.fail)
let switchedAt = moments.now
advance(&moments, seconds: 25)
let winOnly = Set((ChatContent.events["Win"] ?? []) + (ChatContent.events["Win.quick"] ?? [])).subtracting((ChatContent.events["Fail"] ?? []) + (ChatContent.events["Fail.quick"] ?? []))
let afterSwitch = moments.messages.filter { $0.source == .eventReaction && $0.postedAt > switchedAt }
check(!afterSwitch.contains { winOnly.contains($0.text) }, "Reactions to a replaced moment are not shown late")
check((moments.metrics.dropped[.staleContext] ?? 0) - droppedBefore == pendingWin, "Every queued reaction to the replaced moment is cancelled")
var cameraTotal = 0, cameraOK = true
for seed: UInt64 in 10..<20 {
    var camera = Simulation(settings: quiet, seed: seed)
    camera.reactToCamera(.movement)
    let movementAt = camera.now
    advance(&camera, seconds: 20)
    let cameraReactions = camera.messages.filter { $0.source == .eventReaction && $0.postedAt > movementAt }
    cameraTotal += cameraReactions.count
    if cameraReactions.count > 2 || !cameraReactions.allSatisfy({ $0.postedAt - movementAt >= 2 }) { cameraOK = false }
}
check(cameraOK && cameraTotal > 0, "Camera cues get at most two later reactions, and sometimes none")
// The host coming back cancels "where did you go" reactions still waiting (review finding F13).
var away = Simulation(settings: quiet, seed: 33)
away.reactToCamera(.faceAway)
advance(&away, seconds: 6)
let awayPending = away.pending.filter { $0.source == .eventReaction }.count
check(away.reactToCamera(.faceBack) && away.context == .faceBack, "A quick return is not swallowed by the camera cooldown")
let backAt = away.now
advance(&away, seconds: 25)
let awayLines = Set((ChatContent.events["Face out of frame"] ?? []) + (ChatContent.events["Face out of frame.quick"] ?? []))
check(!away.messages.contains { $0.postedAt > backAt && awayLines.contains($0.text) } && (awayPending == 0 || (away.metrics.dropped[.staleContext] ?? 0) > 0), "Nobody asks where the host went after they are back")
var noAway = Simulation(settings: quiet, seed: 34)
check(!noAway.reactToCamera(.faceBack), "A face appearing without having left is not a return")
// Breaks end when the host is back (review finding F1).
var pause = Simulation(settings: quiet, seed: 35)
pause.trigger(.breakTime); check(pause.breakActive, "BRB starts a break")
pause.send("ok i'm back"); check(!pause.breakActive, "Typing that you are back ends the break")
pause.trigger(.breakTime); pause.trigger(.laugh); check(!pause.breakActive, "Any other moment the host marks ends the break")

// MARK: Host text understanding
check(HostIntent.choice(in: "tea or coffee?")! == ("tea", "coffee"), "Simple choice is extracted")
check(HostIntent.choice(in: "should i play ranked or casual?")! == ("ranked", "casual"), "Choice skips filler words")
check(HostIntent.parse("Привет, как дела?").kind == .nonEnglish, "Non-Latin text is recognised as possibly unreadable for viewers")
check(HostIntent.parse("hi chat").kind == .greeting && HostIntent.parse("Do you like cats?").kind == .yesNoQuestion(.general), "Greetings and yes/no questions are recognised")
// Host text classification on realistic lines (review findings F6–F11).
func kindOf(_ text: String) -> HostIntent.Kind { HostIntent.parse(text).kind }
func eventOf(_ text: String) -> StreamEvent? { HostIntent.parse(text).event }
check(eventOf("who won?") == nil && eventOf("I almost won") == nil && eventOf("they won the match") == nil && eventOf("have you ever won anything?") == nil, "Questions, near misses and other people's wins are not a Win")
check(eventOf("i won") == .win && eventOf("we just won!") == .win && eventOf("WON IT") == .win, "First-person wins are a Win")
check(eventOf("brb") == .breakTime && eventOf("i'm back") == .returnLive && eventOf("ok back now") == .returnLive, "Break and return are recognised from text")
check(eventOf("haha that was dumb") == nil, "The host laughing in text is not a staged Laugh moment")
check(kindOf("thanks! what should I play next?") == .openQuestion, "A question after a thank-you is still a question")
check(kindOf("good night chat") == .bye && kindOf("night shift vibes today") != .bye, "Goodbyes need a goodbye phrase, not the word night")
check(kindOf("what a comeback!") == .statement(.news) || kindOf("what a comeback!") == .statement(.filler), "Exclamations are not questions")
check(kindOf("what should i play next") == .openQuestion && kindOf("hey chat what's everyone drinking") == .openQuestion, "Questions without a question mark or after a greeting are questions")
check(kindOf("@lunar_fox tea or coffee?") == .choice("tea", "coffee") && kindOf("@aqua.kiwi68 what are you drinking") == .openQuestion, "Mentions are removed before reading the question")
check(kindOf("i'll do it sooner or later.") != .choice("sooner", "later") && HostIntent.choice(in: "is it this or not?") == nil, "Idioms and 'or not' are not polls")
check(HostIntent.choice(in: "coffee or tea in the morning?")! == ("coffee", "tea") && HostIntent.choice(in: "ok, team coffee or team tea?")! == ("coffee", "tea"), "Options stop at prepositions, clause breaks and 'team'")
check(kindOf("can you hear me?") == .yesNoQuestion(.check) && kindOf("anyone here?") == .yesNoQuestion(.presence) && kindOf("should I stream tomorrow?") == .yesNoQuestion(.advice), "Yes/no questions are told apart by form")
check(kindOf("lol") == .statement(.filler) && kindOf("I think pineapple is fine on pizza") == .statement(.opinion) && kindOf("welcome @lunar_fox") == .statement(.welcome) && kindOf("brb") == .statement(.event), "Statements are told apart: filler, opinion, welcome, event")
check(kindOf("how are we feeling about this boss?") == .openQuestion && kindOf("how is everyone doing?") == .howAreYou, "How-are-you needs the actual phrase")
var words = Simulation(settings: quiet, seed: 91)
words.send("wonderful evening"); check(words.context == nil, "Wonderful does not trigger Win")
words.send("I haven't won yet"); check(words.context == nil, "Negated victory is not a win")
words.send("I won't give up"); check(words.context != .win, "Contraction won't does not become a Win event")
words.send("I won’t give up"); check(words.context != .win, "Curly apostrophe won't does not become a Win event")
let wonCount = words.messages.count
words.send("I WON!!"); check(words.context == .win && words.messages.count == wonCount + 1, "Explicit victory triggers Win with no synchronous reaction")
words.clearCameraContext(); check(words.context == .win, "Turning off camera preserves a manual cue")
var identity = words.settings; identity.streamTitle = "A new title"; identity.channelName = "my_live"; words.apply(identity); words.send("hello folks")
check(words.messages.last?.name == "my_live" && words.settings.streamTitle == "A new title", "Title and channel edits are applied")
for _ in 0..<200 { words.send("hello") }
check(words.messages.count == 160 && words.pending.count <= 60, "Host messages cannot grow chat or the queue without bound")
words.send(String(repeating: "x", count: 300)); check(words.messages.last?.text.count == 200, "Host input length capped")
let beforeEmpty = words.messages.last?.id; words.send("  \n "); check(words.messages.last?.id == beforeEmpty, "Blank host input ignored")
var foreign = Simulation(settings: quiet, seed: 31)
let foreignAt = foreign.now
foreign.send("Привет всем, как дела?")
advance(&foreign, seconds: 40)
check(foreign.messages.filter { $0.source == .hostReply && $0.postedAt > foreignAt }.count <= 1, "Unreadable host text gets at most a light reply and nothing breaks")
check(!viewerMessages(foreign, after: foreignAt).isEmpty, "Chat keeps running after non-English input")

// MARK: Camera scenes
var live = Simulation(settings: quiet, seed: 18)
live.observeScene(.food)
check(live.context == .food && live.activeScenario == .cozy, "A food hint is a moment, not an instant scene change")
for _ in 0..<16 { advance(&live, seconds: 3); live.observeScene(.food) }
check(live.activeScenario == .kitchen, "Food seen steadily for 40+ seconds moves Auto to the food scene")
live.trigger(.win); live.reactToCamera(.movement)
check(live.context == .win, "Manual event wins over camera changes")
advance(&live, seconds: 16); live.reactToCamera(.movement)
check(live.context == .movement, "Camera cues resume after manual priority expires")
var off = live.settings; off.cameraReactions = false; live.apply(off)
check(live.context == nil && live.visualScene == nil && live.activeScenario == .cozy, "Disabling camera clears its cue and scene")
live.observeScene(.pet); check(live.visualScene == nil, "Disabled camera classification cannot change scenario")
var selected = quiet; selected.scenario = .gaming
var fixedScene = Simulation(settings: selected, seed: 18); fixedScene.observeScene(.food)
check(fixedScene.activeScenario == .gaming, "Explicit scenario remains selected despite automatic visual hints")
var mug = Simulation(settings: quiet, seed: 19)
var foodComments = 0
for _ in 0..<100 {
    let before = mug.now
    mug.observeScene(.food); advance(&mug, seconds: 3)
    foodComments += mug.messages.filter { $0.source == .eventReaction && $0.postedAt > before }.count
}
check(foodComments <= 4, "An object that stays in frame is not commented on endlessly")
var sceneGate = SceneCueGate()
check(sceneGate.observe(.food, at: 0) == nil && sceneGate.observe(.food, at: 3) == nil, "Single and double classification hits do not change scene")
check(sceneGate.observe(.food, at: 6) == .food, "Three consistent observations confirm visual scene")
check(sceneGate.observe(nil, at: 9) == .food && sceneGate.observe(nil, at: 12) == nil, "Scene clears after two misses")
check(VisualScene.classify(identifier: "hotdog", confidence: 0.98) == nil, "Substring hotdog is not misread as a pet dog")
check(VisualScene.classify(identifier: "dog", confidence: 0.5) == nil && VisualScene.classify(identifier: "dog", confidence: 0.9) == .pet, "Classification requires sufficient confidence")
func sample(face: Bool = true, smile: Bool = false, motion: Double = 0) -> CameraObservation { .init(faceVisible: face, smiling: smile, motion: motion) }
var gate = CameraCueGate(), cues: [StreamEvent] = []
for step in 0...60 { if let e = gate.observe(sample(smile: step >= 8), at: Double(step)/2, frontCamera: true) { cues.append(e) } }
check(cues == [.smile], "A held smile emits once instead of repeated camera commentary")
var faceGate = CameraCueGate(), faceCues: [StreamEvent] = []
for step in 0...50 { let t = Double(step)/2; if let e = faceGate.observe(sample(face: t < 5 || t >= 13), at: t, frontCamera: true) { faceCues.append(e) } }
check(faceCues == [.faceAway, .faceBack], "Face disappearance and return need sustained confirmation")
var rear = CameraCueGate(), rearCues: [StreamEvent] = []
for step in 0...50 { if let e = rear.observe(sample(face: false), at: Double(step)/2, frontCamera: false) { rearCues.append(e) } }
check(rearCues.isEmpty, "Rear camera without face does not imply the host left")
var flicker = CameraCueGate(), flickerEvents: [StreamEvent] = []
for step in 0...80 { if let e = flicker.observe(sample(face: step % 2 == 0, smile: step % 2 == 0, motion: step % 2 == 0 ? 0.5 : 0), at: Double(step)/2, frontCamera: true) { flickerEvents.append(e) } }
check(flickerEvents.isEmpty, "Brief visual flicker is filtered")

// MARK: On-device writer contract
var writerSettings = quiet; writerSettings.localWriting = true
var written = Simulation(settings: writerSettings, seed: 333)
var request: WritingRequest? = nil
for question in ["What should I cook this weekend?", "What are you all drinking tonight?", "What's everyone snacking on?", "What music are you listening to lately?", "Where would you travel next?", "What's your comfort food?"] where request?.slots.isEmpty ?? true {
    written.send(question)
    request = written.makeWritingRequest()
}
let slots = request?.slots ?? []
check(!slots.isEmpty && slots.allSatisfy { $0.kind == .replyToHost }, "Scheduled replies to the host are offered to the writer")
check(slots.allSatisfy { slot in written.pending.first { $0.id == slot.id }.flatMap { written.audience[$0.participant]?.voice.summary } == slot.voice }, "Each slot carries its planned author's writing habits")
let plannedAuthors = Dictionary(uniqueKeysWithValues: written.pending.map { ($0.id, $0.participant) })
var texts: [UUID: String] = [:]
for (i, slot) in slots.enumerated() { texts[slot.id] = ["probably something with rice", "soup, it's getting cold", "whatever is in the fridge", "leftovers if i'm honest"][i % 4] }
let accepted = written.acceptWriting(WritingResult(slotTexts: texts, ambient: []), for: request!)
check(accepted >= 1, "Valid generated replies are accepted")
check(written.acceptWriting(WritingResult(slotTexts: [slots[0].id: "@someone buy this for $5"], ambient: []), for: request!) == 0 && !written.pending.contains { $0.text.contains("@someone") }, "Model lines with mentions or money are rejected")
advance(&written, seconds: 70)
let shownSlots = slots.compactMap { slot -> ChatMessage? in written.messages.first { $0.text == texts[slot.id] && $0.source == .hostReply } }
check(!shownSlots.isEmpty && shownSlots.allSatisfy { m in m.replyToHost && slots.contains { plannedAuthors[$0.id] == m.participantID && texts[$0.id] == m.text } }, "Generated replies are shown by the planned author, addressed to the host")
check(written.metrics.modelDelivered >= shownSlots.count, "Shown model lines are counted")
let ambientRequest = written.makeWritingRequest()
check(ambientRequest != nil && ambientRequest!.ambientCount > 0, "Writer is asked for fresh neutral lines")
check(written.acceptWriting(WritingResult(slotTexts: [:], ambient: ["anyone else's cat sitting on the keyboard rn", "my tea went cold again"]), for: ambientRequest!) == 2, "Fresh neutral lines are accepted into the buffer")
written.send("Any plans for tonight?")
let lateRequest = written.makeWritingRequest()
advance(&written, seconds: 90)
let lateAccepted = written.acceptWriting(WritingResult(slotTexts: Dictionary(uniqueKeysWithValues: (lateRequest?.slots ?? []).map { ($0.id, "this arrived far too late") }), ambient: []), for: lateRequest ?? ambientRequest!)
check(lateAccepted == 0 && !written.messages.contains { $0.text == "this arrived far too late" }, "Late generation results are discarded, not shown out of context")
var titleSettings = writerSettings; titleSettings.streamTitle = "Friday coffee chat"
written.apply(titleSettings)
let titledRequest = written.makeWritingRequest()
check(titledRequest?.streamTitle == "Friday coffee chat", "Editable title reaches on-device writing context")
written.pause()
check(written.acceptWriting(WritingResult(slotTexts: [:], ambient: ["should not arrive during a pause"]), for: titledRequest!) == 0, "Paused stream rejects in-flight generated content")
written.resume()
// Old results cannot leak into a new scene or a replaced moment (v5 check, restored).
var stale = Simulation(settings: writerSettings, seed: 444)
stale.trigger(.win)
let eventRequest = stale.makeWritingRequest()
stale.trigger(.fail)
var staleSettings = stale.settings; staleSettings.scenario = .gaming; stale.apply(staleSettings)
let staleTexts = Dictionary(uniqueKeysWithValues: (eventRequest?.slots ?? []).map { ($0.id, "stale wording for an old moment") })
check(eventRequest != nil && stale.acceptWriting(WritingResult(slotTexts: staleTexts, ambient: ["stale ambient line from the old scene"]), for: eventRequest!) == 0, "Old generation results cannot leak into a new scene or a replaced moment")
let parsedRequest = WritingRequest(category: "Just Chatting", streamTitle: "t", visualHint: "", recentChat: [], slots: [WritingSlot(id: UUID(), kind: .replyToHost, voice: "short", about: "hi", maxLength: 60)], ambientCount: 1)
check(WritingResult.parse("```json\n{\"line1\":\"hey\",\"ambient\":[\"hello chat\"]}\n```", request: parsedRequest)?.ambient == ["hello chat"], "Structured local model response parser")
check(WritingResult.parse("not JSON", request: parsedRequest) == nil && WritingResult.parse("}{", request: parsedRequest) == nil && WritingResult.parse(String(repeating: "x", count: 13000), request: parsedRequest) == nil, "Malformed or oversized writing is rejected")
check(!Simulation.acceptableModelLine("привет всем", maxLength: 60) && !Simulation.acceptableModelLine("#ad check this", maxLength: 60) && Simulation.acceptableModelLine("my tea went cold again", maxLength: 60), "Model output in another language or with tags is rejected")

// MARK: Donors are members of the audience
var tips = Simulation(settings: quiet, seed: 717)
var notes = Set<String>(); var silentTips = 0
for _ in 0..<300 {
    check(tips.donate(), "Accept next tip")
    let tip = tips.donation!
    if tip.returning && tip.message.lowercased().contains("first") { fatalError("Returning donor claims to be new: \(tip.message)") }
    if tip.message.isEmpty { silentTips += 1 }
    else { guard notes.insert(TextMemory.canonical(tip.message)).inserted else { fatalError("Tip note repeated") } }
    check(tips.audience[tip.participantID] != nil, "Donor is a known participant")
    advance(&tips, seconds: 15)
}
let perDonor = tips.audience.people.reduce(0) { $0 + $1.sessionTipTotal }
check(perDonor == tips.total, "Every dollar is counted once and attributed to one donor")
check(tips.audience.people.contains { $0.sessionTips >= 2 }, "Some supporters give more than once")
check(notes.count > 25 && silentTips > 0, "Non-repeating notes; honest message-free tips after exhaustion")
var thanks = Simulation(settings: quiet, seed: 88)
thanks.donate()
let donorID = thanks.donation!.participantID
advance(&thanks, seconds: 2)
check(thanks.thankLatestDonor(), "Host can thank the latest supporter")
let thankedAt = thanks.now
advance(&thanks, seconds: 40)
let donorReplies = thanks.messages.filter { $0.participantID == donorID && $0.postedAt > thankedAt && $0.replyToHost }
check(donorReplies.count <= 1 && donorReplies.allSatisfy { $0.postedAt - thankedAt >= 2 && $0.replyToHost }, "Thanked donor answers at most once, later, as the same person")
let thanksMessage = thanks.messages.first { $0.isHost && $0.postedAt == thankedAt }!
let othersAnsweringThanks = thanks.messages.filter { $0.postedAt > thankedAt && $0.replyToHost && $0.participantID != donorID && $0.source == .hostReply }
check(othersAnsweringThanks.isEmpty, "Thanking one supporter by name does not draw replies from strangers")
_ = thanksMessage

// MARK: Persistent community
let snapshot = tips.communitySnapshot
let encoded = try JSONEncoder().encode(snapshot)
let decoded = try JSONDecoder().decode(CommunitySnapshot.self, from: encoded)
var returning = Simulation(settings: quiet, seed: 99, community: decoded.people)
check(decoded.people.count >= 60 && Set(decoded.people.map(\.name)).isSubset(of: Set(returning.audience.people.map(\.name))), "Community members return in the next session")
check(returning.audience.people.reduce(0) { $0 + $1.pastTipTotal } == tips.total && returning.total == 0, "Past gifts are remembered as history, not counted again")
check((try? JSONDecoder().decode(CommunitySnapshot.self, from: Data("{broken".utf8))) == nil, "Corrupt community data is rejected")
var neverLive = Simulation(settings: quiet, seed: 98, community: decoded.people)
neverLive.prepare(); advance(&neverLive, seconds: 5)
let beforeHistory = decoded.people.reduce(0) { $0 + $1.streamsChatted }
check(neverLive.communitySnapshot.people.reduce(0) { $0 + $1.streamsChatted } == beforeHistory, "Warm-up chatter before Go live adds no history")
var corrupt = decoded.people[0]; corrupt = Participant(id: 9999, name: "broken_one", avatar: "BO", color: 77, personality: .joker, voice: Voice(casual: .nan, brevity: 5, chattiness: -1, attention: 0, noticeLag: 1e9, readingWordsPerSecond: 0, typingCharactersPerSecond: 0, curiosity: 2, generosity: -3), regular: true)
let repaired = Simulation(settings: quiet, seed: 97, community: [corrupt]).audience[9999]
check(repaired != nil && (0...5).contains(repaired!.color) && repaired!.voice.typingCharactersPerSecond >= 2 && repaired!.voice.noticeLag <= 6, "Out-of-range stored values are repaired instead of crashing")
returning.donate(); check(returning.donation != nil, "A session with restored audience runs normally")

// MARK: Stream lifecycle (D2)
var cycle = Simulation(settings: quiet, seed: 61)
cycle.prepare()
let readyCount = cycle.messages.count
advance(&cycle, seconds: 20); cycle.send("hello?"); cycle.togglePause()
check(cycle.phase == .ready && !cycle.running && cycle.elapsed == 0 && cycle.messages.count == readyCount, "Before Go live nothing moves, even Resume")
cycle.goLive(); advance(&cycle, seconds: 30)
check(cycle.phase == .live && cycle.elapsed == 30 && cycle.messages.count > readyCount, "Go live starts the timer and chat")
cycle.donate(); cycle.send("thanks for coming"); cycle.end()
let endedCount = cycle.messages.count
advance(&cycle, seconds: 30); cycle.togglePause(); cycle.goLive()
check(cycle.phase == .ended && !cycle.running && cycle.pending.isEmpty && cycle.messages.count == endedCount, "Ending stops chat and cancels queued replies")
let summary = cycle.summary
check(summary.total == cycle.total && summary.gifts == 1 && summary.duration == 30 && summary.peakViewers >= cycle.viewers && summary.topSupporters.count == 1, "Summary matches what happened")

// MARK: Settings migration
var old = try JSONDecoder().decode(Settings.self, from: Data(#"{"messagesPerMinute":32,"donationsPerMinute":1,"scenario":"Late night gaming","channelName":"mychannel","cameraReactions":false}"#.utf8))
check(old.messagesPerMinute == 32 && old.channelName == "mychannel" && !old.cameraReactions, "Migration keeps identity, chat speed and camera preference")
check(old.scenario == .automatic && old.donationsPerMinute == 0.85 && old.schemaVersion == 6 && old.pauseModelInLowPower, "v4 settings migrate to automatic voices and slower tips once")
let again = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(old))
check(again.donationsPerMinute == 0.85, "Migration is not applied again on each launch")
let v5 = try JSONDecoder().decode(Settings.self, from: Data(#"{"schemaVersion":5,"scenario":"Cooking & food","localWriting":false,"tipDuration":9}"#.utf8))
check(v5.scenario == .kitchen && !v5.localWriting && v5.tipDuration == 9 && v5.schemaVersion == 6, "v5 settings carry over to v6")
old.channelName = "   "; old.streamTitle = String(repeating: "a", count: 100); old.minAmount = -.infinity; old.tipDuration = .nan; old.normalize()
check(old.channelName == "nightshift" && old.streamTitle.count == 80 && old.minAmount == 10 && old.tipDuration == 7, "Corrupt settings and text limits normalize")

// MARK: Amounts
var dollarRandom = StreamRandom(state: 1707), sampler = DollarSampler(), recent: [Int] = []
var standard = 0, small = 0, large = 0, roundRepeats = 0
for _ in 0..<20000 {
    let amount = sampler.next(using: &dollarRandom)
    guard (10...900).contains(amount) else { fatalError("Invalid amount") }
    if recent.contains(amount) {
        guard amount % 50 == 0 else { fatalError("Non-round amount repeated within ten tips") }
        roundRepeats += 1
    }
    if amount < 100 { small += 1 } else if amount <= 200 { standard += 1 } else { large += 1 }
    recent.append(amount); if recent.count > 10 { recent.removeFirst() }
}
check((0.78...0.82).contains(Double(standard)/20000), "About 80% of tips remain between $100 and $200")
check((0.15...0.19).contains(Double(small)/20000) && (0.02...0.04).contains(Double(large)/20000), "Small and rare larger tip proportions remain intact")
check(roundRepeats > 100, "Round amounts like $100 or $150 can recur naturally")
check(USD.format(1500) == "$1,500", "Dollar formatting is independent of phone locale")
var narrow = DollarSampler()
check((0..<50).allSatisfy { _ in narrow.next(minimum: 150, maximum: 150, using: &dollarRandom) == 150 }, "A single allowed amount remains valid")

// MARK: One hour without the model (E6)
for seed: UInt64 in [42, 100, 4242] {
    var hour = Simulation(settings: quiet, seed: seed)
    var longLines: [String: Int] = [:]
    var lastPost = 0.0, count = 0, seen = Set<UUID>()
    var maxGap = 0.0, previous = 0.0
    var authorsPerMinute: [Int: Set<Int>] = [:]
    for second in 0..<3600 {
        for _ in 0..<4 { hour.tick(0.25) }
        // Two runs move through scenes every ten minutes; one stays in Auto for the whole hour.
        if seed != 4242 && second % 600 == 0 && second > 0 { var s = hour.settings; s.scenario = Scenario.allCases[(second / 600) % 8]; hour.apply(s) }
        for m in hour.messages.suffix(8) where !m.isHost && !m.isDonation && seen.insert(m.id).inserted {
            count += 1; lastPost = hour.elapsed
            maxGap = max(maxGap, hour.elapsed - previous); previous = hour.elapsed
            if !Simulation.isShort(m.text) { longLines[TextMemory.canonical(m.text), default: 0] += 1 }
            if let id = m.participantID { authorsPerMinute[second / 60, default: []].insert(id) }
        }
    }
    let repeats = longLines.values.filter { $0 > 1 }.count
    let authors = authorsPerMinute.values.map(\.count).sorted()
    print(String(format: "Offline hour seed %llu: %d messages, last at %.0fs, longest silence %.0fs, repeated long lines %d, authors/min median %d, exhausted %@",
                 seed, count, lastPost, maxGap, repeats, authors[authors.count / 2], hour.contentExhausted ? "yes" : "no"))
    print("  delivered by source: " + MessageSource.allCases.map { "\($0.rawValue)=\(hour.metrics.delivered[$0] ?? 0)" }.joined(separator: " "))
    check(lastPost > 3500 && count > 450, "Offline chat keeps going for a full hour (seed \(seed))")
    check(repeats == 0, "No long line repeats within the hour (seed \(seed))")
    check(maxGap < 60, "No minute-long dead air (seed \(seed))")
    check(hour.metrics.sameUpdateReplies == 0, "Nothing replies in the same moment as its cause (seed \(seed))")
}

print("Final: \(checks) checks passed")

// MARK: Sample transcripts for human review (F1). Printed, not asserted.
func transcript(_ title: String, seed: UInt64, scenario: Scenario = .automatic, script: [(Double, (inout Simulation) -> Void)], seconds: Double) {
    var settings = quiet; settings.scenario = scenario
    var s = Simulation(settings: settings, seed: seed)
    let start = s.now
    var shown = Set(s.messages.map(\.id))
    var actions = script.sorted { $0.0 < $1.0 }
    print("\n=== \(title) ===")
    var t = 0.0
    while t < seconds {
        while let next = actions.first, next.0 <= t { actions.removeFirst(); next.1(&s) }
        s.tick(0.25); t += 0.25
        for m in s.messages where shown.insert(m.id).inserted {
            let who = m.isHost ? "[HOST] \(m.name)" : m.name
            let reply = m.replyTo.map { " ↳\($0)" } ?? ""
            print(String(format: "%6.1f  ", m.postedAt - start) + who + reply + ": " + m.text)
        }
    }
}
transcript("Host asks a choice question", seed: 501, script: [(20, { $0.send("Tea or coffee?") })], seconds: 75)
transcript("Host asks an open question, then a viewer question", seed: 502, script: [(10, { $0.send("What should I make for dinner tonight?") }), (60, { $0.send("hi chat, how are you all doing?") })], seconds: 110)
transcript("Manual Win, then Fail", seed: 503, scenario: .gaming, script: [(15, { $0.trigger(.win) }), (50, { $0.trigger(.fail) })], seconds: 90)
transcript("Tip, then thanks", seed: 504, script: [(10, { _ = $0.donate() }), (18, { _ = $0.thankLatestDonor() })], seconds: 60)
transcript("Quiet study scene, BRB and back", seed: 505, scenario: .study, script: [(30, { $0.trigger(.breakTime) }), (75, { $0.trigger(.returnLive) })], seconds: 120)
