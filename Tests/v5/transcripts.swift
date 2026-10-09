import Foundation
// Runs the same review situations on the v5 engine (sources from commit 1291a07, the imported v5 baseline) for comparison (F1).
setvbuf(stdout, nil, _IOLBF, 0)
var quiet = Settings(); quiet.donationsPerMinute = 0; quiet.localWriting = false
func transcript(_ title: String, seed: UInt64, scenario: Scenario = .automatic, script: [(Double, (inout Simulation) -> Void)], seconds: Double) {
    var settings = quiet; settings.scenario = scenario
    var s = Simulation(settings: settings, seed: seed)
    var shown = Set(s.messages.map(\.id))
    var actions = script.sorted { $0.0 < $1.0 }
    print("\n=== v5: \(title) ===")
    var t = 0.0
    func flush() {
        for m in s.messages where shown.insert(m.id).inserted {
            let who = m.isHost ? "[HOST] \(m.name)" : m.name
            let reply = m.replyTo.map { " ↳\($0)" } ?? ""
            print(String(format: "%6.1f  ", t) + who + reply + ": " + m.text)
        }
    }
    while t < seconds {
        while let next = actions.first, next.0 <= t { actions.removeFirst(); next.1(&s); flush() }
        s.tick(0.25); t += 0.25
        flush()
    }
}
transcript("Host asks a choice question", seed: 501, script: [(20, { $0.send("Tea or coffee?") })], seconds: 75)
transcript("Host asks an open question, then a viewer question", seed: 502, script: [(10, { $0.send("What should I make for dinner tonight?") }), (60, { $0.send("hi chat, how are you all doing?") })], seconds: 110)
transcript("Manual Win, then Fail", seed: 503, scenario: .gaming, script: [(15, { $0.trigger(.win) }), (50, { $0.trigger(.fail) })], seconds: 90)
transcript("Tip", seed: 504, script: [(10, { _ = $0.donate() })], seconds: 40)
