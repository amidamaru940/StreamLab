import SwiftUI
import Combine

// Keep the classic SwiftUI property wrapper across iOS 17–27 SDKs.
private typealias ViewState<Value> = SwiftUI.State<Value>

/// E1: what the on-device model actually did, kept separate from "is it available".
struct ModelDiagnostics {
    var availability = LocalChatWriter.Availability(ready: false, code: "checking", detail: "Checking…")
    var languages = ""
    var requests = 0, successes = 0, failures = 0
    var linesAccepted = 0
    var lastLatency: Double?
    var lastSuccess: Date?
    var lastError: String?
    var lastErrorAt: Date?
    var testRunning = false
    var testResult: String?
    var system: String { "iOS " + ProcessInfo.processInfo.operatingSystemVersionString }
}

@MainActor final class StreamStore: ObservableObject {
    @Published var engine: Simulation
    @Published private(set) var diagnostics = ModelDiagnostics()
    private var writingTask: Task<Void, Never>?
    private var nextWritingAllowed = -Double.infinity
    private var failureStreak = 0
    private var lastAvailabilityCheck = -Double.infinity
    private var lastCommunitySave = ProcessInfo.processInfo.systemUptime
    private var timer: AnyCancellable?
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private static let settingsKey = "streamlab.settings.v5"
    private static let communityKey = "streamlab.community.v1"
    init() {
        // Migrate existing USD settings once; v5 adds mixed chat and slower tips.
        let saved = UserDefaults.standard.data(forKey: Self.settingsKey) ?? UserDefaults.standard.data(forKey: "streamlab.settings.v3")
        let settings = saved.flatMap { try? JSONDecoder().decode(Settings.self, from: $0) } ?? Settings()
        engine = Simulation(settings: settings, community: Self.loadCommunity())
        diagnostics.languages = LocalChatWriter.languageSummary
        timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            self.engine.tick(now - self.lastTick)
            self.lastTick = now
            self.refreshWriting(now: now)
            if now - self.lastCommunitySave > 60 { self.saveCommunity() }
        }
    }
    /// What the reaction engine is using right now and why (E4).
    var writingStatus: String {
        if !engine.settings.localWriting { return "Using the offline library · on-device writing is off" }
        if !diagnostics.availability.ready { return "Using the offline library · " + diagnostics.availability.detail }
        if let error = diagnostics.lastError, let at = diagnostics.lastErrorAt, at > (diagnostics.lastSuccess ?? .distantPast) {
            return "Using the offline library · last on-device attempt failed: " + error
        }
        if diagnostics.lastSuccess != nil { return "Apple Intelligence · writing on this iPhone" }
        return "Apple Intelligence available · waiting for the first lines"
    }
    func save(_ settings: Settings) {
        engine.apply(settings)
        if let data = try? JSONEncoder().encode(engine.settings) { UserDefaults.standard.set(data, forKey: Self.settingsKey) }
        lastAvailabilityCheck = -.infinity
    }
    func reset() {
        writingTask?.cancel(); writingTask = nil
        saveCommunity()
        engine = Simulation(settings: engine.settings, community: Self.loadCommunity())
        nextWritingAllowed = -.infinity
    }
    func stopWriting() { writingTask?.cancel(); writingTask = nil }
    func saveCommunity() {
        lastCommunitySave = ProcessInfo.processInfo.systemUptime
        if let data = try? JSONEncoder().encode(engine.communitySnapshot) { UserDefaults.standard.set(data, forKey: Self.communityKey) }
    }
    private static func loadCommunity() -> [Participant]? {
        guard let data = UserDefaults.standard.data(forKey: communityKey),
              let snapshot = try? JSONDecoder().decode(CommunitySnapshot.self, from: data), snapshot.version == 1 else { return nil }
        return snapshot.people
    }
    func runModelTest() {
        guard !diagnostics.testRunning else { return }
        diagnostics.testRunning = true; diagnostics.testResult = nil
        let started = ProcessInfo.processInfo.systemUptime
        Task { [weak self] in
            do {
                let text = try await LocalChatWriter.selfTest()
                guard let self else { return }
                let seconds = ProcessInfo.processInfo.systemUptime - started
                self.diagnostics.testResult = String(format: "OK in %.1f s: ", seconds) + "“" + String(text.prefix(120)) + "”"
            } catch {
                self?.diagnostics.testResult = "Failed: " + LocalChatWriter.describe(error)
            }
            self?.diagnostics.testRunning = false
        }
    }
    private func refreshWriting(now: Double) {
        if !engine.running || !engine.settings.localWriting {
            if writingTask != nil { writingTask?.cancel(); writingTask = nil }
            return
        }
        if now - lastAvailabilityCheck >= 3 {
            lastAvailabilityCheck = now
            diagnostics.availability = LocalChatWriter.availability(pauseInLowPower: engine.settings.pauseModelInLowPower)
        }
        // E2: small, frequent requests. Generation does not delay chat: lines are already scheduled with library text.
        guard diagnostics.availability.ready, writingTask == nil, now >= nextWritingAllowed,
              let request = engine.makeWritingRequest() else { return }
        nextWritingAllowed = now + 4
        diagnostics.requests += 1
        writingTask = Task { [weak self] in
            let started = ProcessInfo.processInfo.systemUptime
            do {
                let result = try await LocalChatWriter.generate(request)
                guard !Task.isCancelled, let self else { return }
                let accepted = self.engine.acceptWriting(result, for: request)
                self.diagnostics.successes += 1
                self.diagnostics.linesAccepted += accepted
                self.diagnostics.lastLatency = ProcessInfo.processInfo.systemUptime - started
                self.diagnostics.lastSuccess = Date()
                self.failureStreak = 0
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.diagnostics.failures += 1
                self.diagnostics.lastError = LocalChatWriter.describe(error)
                self.diagnostics.lastErrorAt = Date()
                self.failureStreak += 1
                // Back off after repeated failures; the offline library keeps the chat going meanwhile.
                self.nextWritingAllowed = ProcessInfo.processInfo.systemUptime + min(120, 10 * pow(2, Double(min(self.failureStreak, 4))))
            }
            self?.writingTask = nil
        }
    }
}

@main struct StreamLabApp: App {
    @StateObject private var store = StreamStore()
    var body: some Scene {
        WindowGroup { LiveView(store: store).preferredColorScheme(.dark).environment(\.locale, Locale(identifier: "en_US")) }
    }
}
private let accent = Color(red: 0.65, green: 0.43, blue: 1)
private let surface = Color(red: 0.095, green: 0.095, blue: 0.115)
private let avatarColors: [Color] = [.purple, .teal, .orange, .pink, .blue, .green]

struct LiveView: View {
    @ObservedObject var store: StreamStore
    @StateObject private var camera = CameraController()
    @ViewState private var cameraEnabled = false
    @ViewState private var showSettings = false
    @ViewState private var showEvents = false
    @ViewState private var showTitleEditor = false
    @ViewState private var draft = ""
    @ViewState private var followChat = true
    @ViewState private var unseen = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                stage.frame(height: max(145, min(350, geometry.size.height * 0.39)))
                channel.padding(.horizontal, 16).padding(.vertical, 12)
                chat.frame(maxHeight: .infinity)
                composer
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.065))
        .sheet(isPresented: $showSettings) { SettingsView(store: store) }
        .sheet(isPresented: $showEvents) { eventControls.presentationDetents([.large]) }
        .sheet(isPresented: $showTitleEditor) { TitleEditor(store: store).presentationDetents([.medium]) }
        .onChange(of: store.engine.running) { _, running in
            if running && cameraEnabled && scenePhase == .active { camera.start() } else { camera.stop() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Backgrounding pauses everything. Permission sheets only make the scene inactive.
            if phase == .background { store.engine.pause(); store.stopWriting(); store.saveCommunity(); camera.stop() }
            if phase == .active && cameraEnabled && store.engine.running { camera.start() }
        }
        .onAppear { camera.setAnalysisEnabled(store.engine.settings.cameraReactions) }
        .onChange(of: store.engine.settings.cameraReactions) { _, enabled in camera.setAnalysisEnabled(enabled) }
        .onChange(of: camera.status) { _, status in
            if status != .live && store.engine.running { store.engine.clearCameraContext() }
        }
        .onReceive(camera.$cue) { cue in
            guard let cue, cameraEnabled, camera.status == .live, scenePhase == .active else { return }
            store.engine.reactToCamera(cue.event)
        }
        .onReceive(camera.$scene) { scene in
            guard cameraEnabled, camera.status == .live, scenePhase == .active else { return }
            store.engine.observeScene(scene)
        }
        .onDisappear { camera.stop(); store.stopWriting() }
    }
    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(accent)
            Text("streamlab").font(.title3.bold())
            Spacer()
            Text("CREATOR").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                .accessibilityLabel("Stream settings").tint(.white)
        }.padding(.leading, 16).padding(.trailing, 6)
    }
    private var stage: some View {
        ZStack {
            Color.black
            CameraPreview(session: camera.session, device: camera.device, mirror: camera.isFront)
                .opacity(camera.status == .live && store.engine.running && cameraEnabled ? 1 : 0)
                .accessibilityHidden(true)
            if camera.status != .live || !store.engine.running || !cameraEnabled {
                VStack(spacing: 12) {
                    Image(systemName: "video.badge.waveform").font(.system(size: 32, weight: .light)).foregroundStyle(accent)
                    Text(!store.engine.running ? "Stream paused" : camera.status.title).font(.headline)
                    if store.engine.donation == nil {
                        Text(!store.engine.running ? "Your camera and chat are on hold." : camera.status.detail)
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        if store.engine.running {
                            if camera.status == .denied {
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                                }.buttonStyle(.borderedProminent).tint(accent)
                            } else {
                                Button(camera.status == .failed || camera.status == .interrupted ? "Retry camera" : "Enable camera") {
                                    cameraEnabled = true; camera.start()
                                }.buttonStyle(.borderedProminent).tint(accent)
                                    .disabled(camera.status == .requesting || camera.status == .starting)
                            }
                        }
                    }
                }.padding(.horizontal, 35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: store.engine.donation == nil ? .center : .top)
                    .padding(.top, store.engine.donation == nil ? 0 : 50)
            }
            VStack {
                HStack(spacing: 8) {
                    Text(store.engine.running ? "LIVE" : "PAUSED").font(.system(size: 10, weight: .heavy))
                        .padding(.horizontal, 8).padding(.vertical, 5).background(store.engine.running ? Color.red : Color.gray, in: RoundedRectangle(cornerRadius: 4))
                    Text(time).font(.caption.monospacedDigit()).shadow(radius: 3)
                    Spacer()
                }
                Spacer()
                if let donation = store.engine.donation {
                    DonationBanner(donation: donation, progress: store.engine.donationProgress)
                        .id(donation.id)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
                if let notice = camera.notice { Text(notice).font(.caption).padding(8).background(.black.opacity(0.8), in: Capsule()) }
                HStack(spacing: 10) {
                    Label(camera.status == .live ? (camera.isFront ? "Front camera" : "Rear camera") : "Camera off", systemImage: "video")
                        .font(.caption).padding(8).background(.black.opacity(0.65), in: Capsule())
                    Spacer()
                    Button {
                        cameraEnabled.toggle()
                        if cameraEnabled { camera.start() } else { camera.stop(); store.engine.clearCameraContext() }
                    } label: { Image(systemName: cameraEnabled ? "video.fill" : "video.slash").frame(width: 44, height: 44).background(.black.opacity(0.6), in: Circle()) }
                        .accessibilityLabel(cameraEnabled ? "Turn camera off" : "Turn camera on").disabled(!store.engine.running)
                    Button { store.engine.clearCameraContext(); camera.flip() } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera").frame(width: 44, height: 44).background(.black.opacity(0.6), in: Circle())
                    }.accessibilityLabel("Switch front and rear cameras").disabled(camera.status != .live || !store.engine.running)
                }.tint(.white)
            }.padding(12)
        }.clipped().animation(reduceMotion ? nil : .spring(response: 0.4), value: store.engine.donation?.id)
    }
    private var channel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(String(store.engine.settings.channelName.prefix(1)).uppercased()).font(.headline.bold()).frame(width: 40, height: 40).background(accent.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Button { showTitleEditor = true } label: {
                        HStack(spacing: 6) {
                            Text(store.engine.settings.streamTitle).font(.headline).lineLimit(2).multilineTextAlignment(.leading)
                            Image(systemName: "pencil").font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain).accessibilityLabel("Edit stream title")
                    Text("\(store.engine.settings.channelName) · \(store.engine.activeScenario.category)").font(.caption).foregroundStyle(accent)
                }
                Spacer(minLength: 4)
                Button { store.engine.togglePause() } label: {
                    Image(systemName: store.engine.running ? "pause.fill" : "play.fill").frame(width: 42, height: 40).background(accent, in: RoundedRectangle(cornerRadius: 9))
                }.tint(.white).accessibilityLabel(store.engine.running ? "Pause stream and camera" : "Resume stream and camera")
            }
            HStack(spacing: 16) {
                Label(store.engine.viewers.formatted(), systemImage: "person.2.fill").foregroundStyle(.red.opacity(0.9))
                Label(USD.format(store.engine.total), systemImage: "gift").foregroundStyle(.secondary)
                Spacer()
                Button { showEvents = true } label: { Label("Studio", systemImage: "square.grid.2x2") }.tint(accent)
            }.font(.caption.bold())
        }
    }
    private var chat: some View {
        VStack(spacing: 0) {
            HStack {
                Text("STREAM CHAT").font(.system(size: 11, weight: .bold))
                Spacer()
                Button { followChat.toggle() } label: { Image(systemName: followChat ? "arrow.down.to.line.circle.fill" : "arrow.down.to.line.circle").frame(width: 36, height: 36) }
                    .accessibilityLabel(followChat ? "Stop chat auto-scroll" : "Follow newest messages").tint(.secondary)
            }.padding(.horizontal, 16).background(surface)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(store.engine.messages) { message in
                            HStack(alignment: .top, spacing: 9) {
                                Text(message.avatar).font(.system(size: 9, weight: .bold))
                                    .frame(width: 26, height: 26).background(avatarColors[message.color].opacity(0.35), in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    if let reply = message.replyTo {
                                        Text("↳ \(reply)").font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    (Text(message.isDonation ? "✦ " : "") + Text(message.name + " ").bold().foregroundColor(avatarColors[message.color]) + Text(message.isHost ? "[HOST] " : "") + Text(message.text))
                                        .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
                                }
                            }.padding(message.isDonation ? 8 : 0)
                                .background(message.isDonation ? accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8)).id(message.id)
                        }
                    }.padding(14)
                }.frame(maxHeight: .infinity)
                    // D3: reading older messages pauses auto-scroll; a pill brings you back.
                    .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { value in if value.translation.height > 24 { followChat = false } })
                    .onChange(of: store.engine.messages.last?.id) { _, id in
                        if followChat, let id { proxy.scrollTo(id, anchor: .bottom) } else { unseen += 1 }
                    }
                    .onChange(of: followChat) { _, follow in
                        if follow { unseen = 0; if let id = store.engine.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) } }
                    }
                    .onAppear { if let id = store.engine.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) } }
                    .overlay(alignment: .bottom) {
                        if !followChat && unseen > 0 {
                            Button { followChat = true } label: {
                                Label(newMessagesLabel, systemImage: "arrow.down")
                                    .font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 8).background(accent, in: Capsule())
                            }.tint(.white).padding(.bottom, 8)
                        }
                    }
            }
        }
    }
    private var composer: some View {
        HStack(spacing: 10) {
            TextField(store.engine.running ? "Send a message" : "Stream paused", text: $draft, axis: .vertical)
                .font(.subheadline).lineLimit(1...2).onChange(of: draft) { _, value in draft = String(value.prefix(200)) }
            Button { store.engine.send(draft); draft = "" } label: { Image(systemName: "paperplane.fill").frame(width: 40, height: 40).foregroundStyle(accent) }
                .accessibilityLabel("Send message").disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.disabled(!store.engine.running).padding(.leading, 12).background(surface, in: RoundedRectangle(cornerRadius: 8)).padding(.horizontal, 12).padding(.vertical, 8)
    }
    private var eventControls: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("SCENES").font(.caption.bold()).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Scenario.allCases) { scenario in
                        Button {
                            var settings = store.engine.settings; settings.scenario = scenario; settings.autoplay = false
                            store.save(settings)
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: scenario.symbol).frame(width: 20)
                                Text(scenario.rawValue).font(.caption.bold()).lineLimit(2)
                                Spacer(minLength: 0)
                                if store.engine.settings.scenario == scenario { Image(systemName: "checkmark.circle.fill") }
                            }.padding(12).frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                                .background(store.engine.settings.scenario == scenario ? accent.opacity(0.2) : surface, in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                }
                Text("MOMENTS").font(.caption.bold()).foregroundStyle(.secondary)
                Text(store.engine.context.map { "Current cue: \($0.rawValue)" } ?? "Choose a moment for chat to react to.").font(.subheadline).foregroundStyle(.secondary)
                if store.engine.libraryRateCap < store.engine.settings.messagesPerMinute {
                    Text(pacingNote).font(.caption).foregroundStyle(.secondary)
                }
                if store.engine.contentExhausted { Text("Chat is quieter: the offline library has used most conversations for this scene. On-device AI, when available, keeps adding fresh lines.").font(.caption).foregroundStyle(.secondary) }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StreamEvent.manualCases) { event in
                        Button { store.engine.trigger(event); showEvents = false } label: {
                            Label(event.rawValue, systemImage: event.symbol).font(.subheadline).frame(maxWidth: .infinity).frame(height: 54).background(surface, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                Button { store.engine.donate(); showEvents = false } label: {
                    Label("Send a tip", systemImage: "gift.fill").frame(maxWidth: .infinity).padding(12)
                }.buttonStyle(.borderedProminent).disabled(store.engine.donationQueue.count >= 12)
                if !store.engine.giftHistory.isEmpty {
                    Text("RECENT GIFTS · \(store.engine.giftHistory.count) · \(USD.format(store.engine.total))").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(store.engine.giftHistory.suffix(6).reversed()) { gift in
                        HStack {
                            Text(gift.name).font(.subheadline).lineLimit(1)
                            if gift.returning { Image(systemName: "arrow.uturn.left.circle").foregroundStyle(.secondary).accessibilityLabel("Returning supporter") }
                            Spacer()
                            Text(USD.format(gift.amount)).font(.subheadline.monospacedDigit().bold())
                        }
                    }
                }
                if let donorID = store.engine.lastDonorID, let donor = store.engine.audience[donorID] {
                    Button { store.engine.thankLatestDonor(); showEvents = false } label: {
                        Label("Thank \(donor.name)", systemImage: "heart").frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.bordered)
                }
                Spacer()
            }.disabled(!store.engine.running).padding(20)
            }.navigationTitle("Creator studio").navigationBarTitleDisplayMode(.inline).tint(accent)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showEvents = false } } }
        }
    }
    private var pacingNote: String {
        "Offline chat is pacing itself at about " + String(Int(store.engine.libraryRateCap.rounded())) + " messages/min so conversations last. Apple Intelligence, when it is writing, lifts this limit."
    }
    private var newMessagesLabel: String {
        if unseen == 1 { return "1 new message" }
        let count = unseen > 99 ? "99+" : String(unseen)
        return count + " new messages"
    }
    private var time: String {
        let s = Int(store.engine.elapsed)
        return String(format: "%02d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
    }
}

private struct DonationBanner: View {
    let donation: Donation
    let progress: Double
    private var highlight: Color { donation.amount >= 500 ? .yellow : accent }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(donation.avatar).font(.system(size: 11, weight: .bold))
                    .frame(width: 34, height: 34).background(avatarColors[donation.color].opacity(0.3), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(donation.name).font(.subheadline.bold()).lineLimit(1)
                    Text(donation.amount >= 500 ? "BIG SUPPORT" : "JUST TIPPED")
                        .font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(highlight)
                }
                Spacer(minLength: 5)
                Text(USD.format(donation.amount)).font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(highlight).monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            }
            if !donation.message.isEmpty { Text(donation.message).font(.system(size: 12)).foregroundStyle(.white.opacity(0.9)).lineLimit(3) }
            GeometryReader { geometry in
                Capsule().fill(highlight.opacity(0.15))
                Capsule().fill(highlight).frame(width: geometry.size.width * min(1, max(0, progress)))
            }.frame(height: 2).accessibilityHidden(true)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.08, green: 0.065, blue: 0.105), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(highlight.opacity(0.4)))
            .accessibilityElement(children: .combine)
    }
}

struct SettingsView: View {
    @ObservedObject var store: StreamStore
    @Environment(\.dismiss) private var dismiss
    @ViewState private var settings = Settings()
    @ViewState private var confirmReset = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Your stream") {
                    TextField("Channel name", text: $settings.channelName).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .onChange(of: settings.channelName) { _, value in settings.channelName = String(value.prefix(24)) }
                    TextField("Stream title", text: $settings.streamTitle)
                        .onChange(of: settings.streamTitle) { _, value in settings.streamTitle = String(value.prefix(80)) }
                    Picker("Scene", selection: $settings.scenario) { ForEach(Scenario.allCases) { Text($0.rawValue).tag($0) } }
                    Toggle("Automatic scene cues", isOn: $settings.autoplay)
                    Text("Optional scripted moments run every 50 seconds. Leave this off when following your real camera.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Audience") {
                    Text("Chat pace · about \(Int(settings.messagesPerMinute))/min")
                    Slider(value: $settings.messagesPerMinute, in: 2...90, step: 1)
                    Text("Mixed voices are automatic: casual chat, questions, humour, support and occasional disagreement. Recent wording is checked for close repeats.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Simulated gifts") {
                    Text("Gift pace · about \(settings.donationsPerMinute.formatted(.number.precision(.fractionLength(2))))/min")
                    Slider(value: $settings.donationsPerMinute, in: 0...12, step: 0.05)
                    Text("Tip notification · \(Int(settings.tipDuration)) seconds")
                    Slider(value: $settings.tipDuration, in: 5...12, step: 1)
                    Text("Minimum · \(USD.format(Int(settings.minAmount)))")
                    Slider(value: $settings.minAmount, in: 10...900, step: 5).onChange(of: settings.minAmount) { _, v in settings.maxAmount = max(v, settings.maxAmount) }
                    Text("Maximum · \(USD.format(Int(settings.maxAmount)))")
                    Slider(value: $settings.maxAmount, in: 10...900, step: 5).onChange(of: settings.maxAmount) { _, v in settings.minAmount = min(v, settings.minAmount) }
                    Text("USD only. About 80% of gifts fall between $100 and $200 at the default $10–$900 limits. Larger gifts are rare. No money is collected.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Reaction engine") {
                    Label("Free · on this iPhone", systemImage: "iphone")
                    Toggle("Use Apple Intelligence when available", isOn: $settings.localWriting)
                    Toggle("Pause it in Low Power Mode", isOn: $settings.pauseModelInLowPower)
                    Text(store.writingStatus).font(.caption).foregroundStyle(.secondary)
                    Text("StreamLab decides who speaks, to whom and when. Apple's on-device model, when available, only rewords lines that are already scheduled. The offline library always keeps chat going. No API key or usage charges.").font(.caption).foregroundStyle(.secondary)
                    NavigationLink("Diagnostics") { DiagnosticsView(store: store) }
                    LabeledContent("Cloud", value: "Not connected")
                    Text("Cloud mode is planned for a later update. This version never uploads your camera frames.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Camera & privacy") {
                    Toggle("React to camera · on device", isOn: $settings.cameraReactions)
                    Text("Uses smiles, face presence, motion and repeated hints of pets, food, outdoor views or instruments. Auto chooses a matching scene. These hints can be wrong. No speech is heard; manual moments take priority for 15 seconds.").font(.caption).foregroundStyle(.secondary)
                    Text("Selected frames are analyzed on this iPhone when camera reactions are on. Nothing is saved or uploaded. No microphone access or API charges. Use Studio if a cue is missed.").font(.footnote).foregroundStyle(.secondary)
                    Text("This is a simulation. Do not present generated viewers or gifts as real on external platforms.").font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("Start a new session", role: .destructive) { confirmReset = true }
                    Text("Resets chat, counters and conversation memory. Settings are kept.").font(.caption).foregroundStyle(.secondary)
                }
            }.navigationTitle("Stream settings").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { store.save(settings); dismiss() } }
                }.onAppear { settings = store.engine.settings }
                .confirmationDialog("Reset this session?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("New session", role: .destructive) { store.save(settings); store.reset(); dismiss() }
                }
        }.tint(accent)
    }
}
struct StreamLabPreview: PreviewProvider {
    static var previews: some View { LiveView(store: StreamStore()).preferredColorScheme(.dark) }
}

struct TitleEditor: View {
    @ObservedObject var store: StreamStore
    @Environment(\.dismiss) private var dismiss
    @ViewState private var title = ""
    @ViewState private var name = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Stream title", text: $title, axis: .vertical).lineLimit(1...3)
                    .onChange(of: title) { _, value in title = String(value.prefix(80)) }
                TextField("Channel name", text: $name).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .onChange(of: name) { _, value in name = String(value.prefix(24)) }
            }.navigationTitle("Edit stream").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { var settings = store.engine.settings; settings.streamTitle = title; settings.channelName = name; store.save(settings); dismiss() }
                    }
                }.onAppear { title = store.engine.settings.streamTitle; name = store.engine.settings.channelName }
        }.tint(accent)
    }
}

/// E1: separates "available", "generated", "accepted" and "shown".
struct DiagnosticsView: View {
    @ObservedObject var store: StreamStore
    var body: some View {
        let d = store.diagnostics
        let m = store.engine.metrics
        Form {
            Section("Apple Intelligence") {
                LabeledContent("System", value: d.system)
                LabeledContent("Model state", value: stateText(d))
                Text(d.availability.detail).font(.caption).foregroundStyle(.secondary)
                Text(d.languages).font(.caption).foregroundStyle(.secondary)
                Button(d.testRunning ? "Testing…" : "Run a quick English test") { store.runModelTest() }.disabled(d.testRunning)
                if let result = d.testResult { Text(result).font(.caption) }
            }
            Section("During this session") {
                LabeledContent("Requests", value: "\(d.requests)")
                LabeledContent("Succeeded / failed", value: "\(d.successes) / \(d.failures)")
                LabeledContent("Lines accepted", value: "\(d.linesAccepted)")
                LabeledContent("Model lines shown", value: "\(m.modelDelivered)")
                LabeledContent("Model lines discarded (late or stale)", value: "\(m.modelDiscarded)")
                if let latency = d.lastLatency { LabeledContent("Last generation", value: String(format: "%.1f s", latency)) }
                if let success = d.lastSuccess { LabeledContent("Last success", value: success.formatted(date: .omitted, time: .standard)) }
                if let error = d.lastError {
                    LabeledContent("Last error", value: d.lastErrorAt?.formatted(date: .omitted, time: .standard) ?? "")
                    Text(error).font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Chat timing") {
                LabeledContent("Messages shown", value: "\(m.totalDelivered)")
                LabeledContent("Viewers in chat now", value: "\(store.engine.presentChatters)")
                if let median = EngineMetrics.median(m.hostReplyDelays), let slow = EngineMetrics.percentile(m.hostReplyDelays, 0.9) {
                    LabeledContent("Replies to you · median / slow", value: String(format: "%.1f s / %.1f s", median, slow))
                }
                if let median = EngineMetrics.median(m.reactionDelays) {
                    LabeledContent("Reactions to moments · median", value: String(format: "%.1f s", median))
                }
                Text(droppedSummary(m)).font(.caption).foregroundStyle(.secondary)
                Text("Counts and timings only. No camera frames, audio or your messages are stored.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Diagnostics").navigationBarTitleDisplayMode(.inline)
    }
    private func stateText(_ d: ModelDiagnostics) -> String { d.availability.ready ? "Available" : "Unavailable" }
    private func droppedSummary(_ m: EngineMetrics) -> String {
        var parts: [String] = []
        for reason in DropReason.allCases { parts.append(reason.rawValue + " " + String(m.dropped[reason] ?? 0)) }
        return "Cancelled before showing: " + parts.joined(separator: " · ")
    }
}
