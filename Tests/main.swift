import Foundation

var checks = 0
func check(_ value: @autoclosure () -> Bool, _ name: String) {
    guard value() else { fatalError("FAIL: \(name)") }
    checks += 1; print("PASS: \(name)")
}
func advance(_ sim: inout Simulation, seconds: Double) {
    for _ in 0..<Int(seconds * 4) { sim.tick(0.25) }
}
var quiet = Settings(); quiet.donationsPerMinute = 0; quiet.localWriting = false
var sim = Simulation(settings: quiet, seed: 42)
check(!sim.messages.isEmpty && sim.activeScenario == .cozy, "Automatic scene starts without inventing camera activity")
check(Scenario.allCases.count == 8, "Eight scenarios including automatic selection")
sim.trigger(.win)
check(sim.context == .win && sim.messages.last?.isHost == false, "Manual event reaches contextual chat")
sim.donate()
let freeze = (sim.elapsed, sim.messages.count, sim.total, sim.donation?.id, sim.donationProgress)
sim.pause(); advance(&sim, seconds: 30); sim.donate(); sim.trigger(.fail); sim.send("test")
check(sim.elapsed == freeze.0 && sim.messages.count == freeze.1 && sim.total == freeze.2 && sim.donation?.id == freeze.3 && sim.donationProgress == freeze.4, "Pause freezes engine, input, tips and progress")
sim.togglePause(); advance(&sim, seconds: 15)
check(sim.donation == nil && sim.elapsed > freeze.0, "Resume expires the longer tip banner")
advance(&sim, seconds: 10)
check(sim.context == nil && sim.total == freeze.2, "Contexts expire; zero tip pace stays off")
let clock = sim.elapsed; sim.tick(1000)
check(sim.elapsed == clock + 1, "No long catch-up after suspension")
let invalidClock = sim.elapsed; sim.tick(.nan); sim.tick(-1); sim.tick(.infinity)
check(sim.elapsed == invalidClock, "Invalid time values are ignored")
var queue = Simulation(settings: quiet, seed: 6)
queue.donate(); let first = queue.donation!.id; let duration = queue.donation!.displayDuration
check(duration >= 7 && duration <= 11, "Default notifications are longer than v4")
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
var slow = Simulation(seed: 72)
check(slow.nextDonation >= 52 && slow.nextDonation <= 96, "Default tips are slightly less frequent with irregular timing")
var fixed = quiet; fixed.minAmount = 500; fixed.maxAmount = 500; fixed.tipDuration = 9
var fixedSim = Simulation(settings: fixed, seed: 1); fixedSim.donate()
check(fixedSim.donation?.amount == 500 && fixedSim.donation!.displayDuration >= 10, "Custom amount and notification time apply")
var memory = TextMemory()
check(memory.accept("The timing was perfect."), "New complete line is accepted")
check(!memory.accept("the timing was perfect!!! 😂"), "Punctuation, case and emoji cannot disguise a repeat")
check(memory.accept("I nearly dropped my tea laughing at that."), "Different topic accepted")
check(!memory.accept("I nearly dropped my tea while laughing at that!"), "Close rewording of a recent line is rejected")
check(!TextMemory.valid("As an AI language model, I cannot watch."), "Model boilerplate rejected")
check(!TextMemory.valid("go to https://example.com"), "Links rejected in generated chat")
check(!TextMemory.valid("first line\nsecond line"), "Multiline generated output rejected")
check(ConversationLibrary.allThreads.flatMap(\.lines).count == 520, "520 authored complete conversation lines")
check(ConversationLibrary.allThreads.allSatisfy { $0.lines.allSatisfy { TextMemory.valid($0) } }, "Curated library has valid complete chat lines")
check(Set(ConversationLibrary.allThreads.map(\.id)).count == ConversationLibrary.allThreads.count, "Conversation identities are unique")
var names = Set<String>(), texts = Set<String>(), count = 0
var marathon = Simulation(settings: quiet, seed: 100)
func collect(_ message: ChatMessage?) {
    guard let m = message, !m.isHost, !m.isDonation else { return }
    guard names.insert(m.name.lowercased()).inserted, texts.insert(TextMemory.canonical(m.text)).inserted else { fatalError("Repeated name or canonical message") }
    count += 1
}
for m in marathon.messages { collect(m) }
for scene in Scenario.allCases {
    var settings = marathon.settings; settings.scenario = scene; marathon.apply(settings)
    for index in 0..<250 {
        let prior = marathon.messages.last?.id
        if index % 9 == 0 { marathon.trigger(StreamEvent.allCases[(index / 9) % StreamEvent.allCases.count]) }
        else { marathon.tick(1) }
        if marathon.messages.last?.id != prior { collect(marathon.messages.last) }
    }
}
check(count > 250 && marathon.messages.count <= 160, "Long mixed session has no canonical repeats and bounded history")
var notes = Set<String>(), donors = Set<String>(); var silentTips = 0
var tips = Simulation(settings: quiet, seed: 717)
for _ in 0..<300 {
    check(tips.donate(), "Accept next tip")
    let tip = tips.donation!
    guard donors.insert(tip.name.lowercased()).inserted else { fatalError("Donor repeated") }
    if tip.message.isEmpty { silentTips += 1 }
    else { guard notes.insert(TextMemory.canonical(tip.message)).inserted else { fatalError("Tip note repeated") } }
    advance(&tips, seconds: 15)
}
check(donors.count == 300 && notes.count > 25 && silentTips > 0, "Unique donors; non-repeating notes; honest message-free tips after exhaustion")
var old = try JSONDecoder().decode(Settings.self, from: Data(#"{"messagesPerMinute":32,"donationsPerMinute":1,"scenario":"Late night gaming","channelName":"mychannel","cameraReactions":false}"#.utf8))
check(old.messagesPerMinute == 32 && old.channelName == "mychannel" && !old.cameraReactions, "Migration keeps identity, chat speed and camera preference")
check(old.scenario == .automatic && old.donationsPerMinute == 0.85 && old.schemaVersion == 5, "v5 migrates to automatic voices and 15% slower tips once")
let again = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(old))
check(again.donationsPerMinute == 0.85, "Migration is not applied again on each launch")
old.channelName = "   "; old.streamTitle = String(repeating: "a", count: 100); old.minAmount = -.infinity; old.tipDuration = .nan; old.normalize()
check(old.channelName == "nightshift" && old.streamTitle.count == 80 && old.minAmount == 10 && old.tipDuration == 7, "Corrupt settings and text limits normalize")
var words = Simulation(settings: quiet, seed: 91)
words.send("wonderful evening"); check(words.context == nil, "Wonderful no longer triggers Win")
words.send("I haven't won yet"); check(words.context == nil, "Negated victory is not a win")
words.send("I WON!!"); check(words.context == .win, "Explicit victory with punctuation works")
words.clearCameraContext(); check(words.context == .win, "Turning off camera preserves a manual cue")
var identity = words.settings; identity.streamTitle = "A new title"; identity.channelName = "my_live"; words.apply(identity); words.send("hello folks")
check(words.messages.last?.name == "my_live" && words.settings.streamTitle == "A new title", "Title and channel edits are applied")
for _ in 0..<200 { words.send("hello") }
check(words.messages.count == 160, "Host messages cannot grow chat without bound")
words.send(String(repeating: "x", count: 300)); check(words.messages.last?.text.count == 200, "Host input length capped")
let beforeEmpty = words.messages.last?.id; words.send("  \n "); check(words.messages.last?.id == beforeEmpty, "Blank host input ignored")
var live = Simulation(settings: quiet, seed: 18)
live.observeScene(.food)
check(live.activeScenario == .kitchen && live.context == .food, "Repeated food detection drives Auto into the food scenario")
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
var writerSettings = quiet; writerSettings.localWriting = true
var written = Simulation(settings: writerSettings, seed: 333)
let token = written.contextToken
check(written.acceptWriting(.init(messages: ["Anyone else building a tiny garden this week?"], tips: ["A bit of support for your garden chat."]), for: token), "Valid on-device writing can enter the chat queue")
advance(&written, seconds: 5)
check(written.acceptedLocalMessages == 1, "Generated text is delivered through the normal chat scheduler")
written.trigger(.win)
check(!written.acceptWriting(.init(messages: ["This should be stale after changing the scene."], tips: []), for: token), "Old generation results cannot leak into a new scene")
let pausedToken = written.contextToken; written.pause()
check(!written.acceptWriting(.init(messages: ["Should not arrive during a pause."], tips: []), for: pausedToken), "Paused stream rejects in-flight generated content")
check(WritingBatch.parse("```json\n{\"messages\":[\"hello chat\"],\"tips\":[]}\n```")?.messages == ["hello chat"], "Structured local model response parser")
check(WritingBatch.parse("not JSON") == nil && WritingBatch.parse(String(repeating: "x", count: 13000)) == nil, "Malformed or oversized writing is rejected")
var dollarRandom = StreamRandom(state: 1707), sampler = DollarSampler(), recent: [Int] = []
var standard = 0, small = 0, large = 0
for _ in 0..<20000 {
    let amount = sampler.next(using: &dollarRandom)
    guard (10...900).contains(amount), !recent.contains(amount) else { fatalError("Invalid amount or recent repeat") }
    if amount < 100 { small += 1 } else if amount <= 200 { standard += 1 } else { large += 1 }
    recent.append(amount); if recent.count > 10 { recent.removeFirst() }
}
check((0.78...0.82).contains(Double(standard)/20000), "About 80% of tips remain between $100 and $200")
check((0.15...0.19).contains(Double(small)/20000) && (0.02...0.04).contains(Double(large)/20000), "Small and rare larger tip proportions remain intact")
check(USD.format(1500) == "$1,500", "Dollar formatting is independent of phone locale")
var narrow = DollarSampler()
check((0..<50).allSatisfy { _ in narrow.next(minimum: 150, maximum: 150, using: &dollarRandom) == 150 }, "A single allowed amount remains valid")
print("Authored session sample: \(count) unique messages. USD sample: \(standard)/\(small)/\(large).")
print("\(checks) checks passed")

check(WritingBatch.parse("}{") == nil, "Malformed reversed JSON delimiters cannot crash the app")
check(!TextMemory.valid("Visit HTTPS://example.com"), "Mixed-case links rejected")
check(!TextMemory.valid("first\rsecond"), "Carriage-return multiline output rejected")
var wording = Simulation(settings: quiet, seed: 80)
wording.send("I won't give up")
check(wording.context != .win, "Contraction won't does not become a Win event")
wording.send("I won’t give up")
check(wording.context != .win, "Curly apostrophe won't does not become a Win event")
var titleSettings = quiet; titleSettings.streamTitle = "Friday coffee chat"
wording.apply(titleSettings)
check(wording.writingContext.streamTitle == "Friday coffee chat", "Editable title reaches on-device writing context")
print("Final: \(checks) checks passed")
