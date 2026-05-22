import SwiftUI
import Combine

enum AppScreen: String {
    case connect
    case signupSymptoms
    case signupDiet
    case signupNotes
    case home
}

@MainActor
class AppState: ObservableObject {
    @Published var screen: AppScreen = .connect

    @Published var profile = Profile()

    @Published var cycleDay: Int = 1
    @Published var cycleLength: Int = 28
    @Published var healthKitLoading: Bool = false
    @Published var healthKitError: String? = nil

    @Published var dailyLog = DailyLog()
    @Published var savedRecipes: [Recipe] = []

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        // Auto-save 500 ms after the last change so no view needs to call save()
        objectWillChange
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    var phaseInfo: CyclePhaseInfo {
        cyclePhase(day: cycleDay, length: cycleLength)
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: "profile"),
           let p = try? decoder.decode(Profile.self, from: data) {
            profile = p
        }

        if let raw = defaults.string(forKey: "screen"),
           let s = AppScreen(rawValue: raw) {
            screen = s
        }

        // DailyLog resets each calendar day
        let today = todayString()
        if defaults.string(forKey: "dailyLogDate") == today,
           let data = defaults.data(forKey: "dailyLog"),
           let log = try? decoder.decode(DailyLog.self, from: data) {
            dailyLog = log
        }

        if let data = defaults.data(forKey: "savedRecipes"),
           let recipes = try? decoder.decode([Recipe].self, from: data) {
            savedRecipes = recipes
        }

        let d = defaults.integer(forKey: "cycleDay")
        cycleDay = d > 0 ? d : 1
        let l = defaults.integer(forKey: "cycleLength")
        cycleLength = l > 0 ? l : 28
    }

    private func save() {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: "profile")
        }
        defaults.set(screen.rawValue, forKey: "screen")
        if let data = try? encoder.encode(dailyLog) {
            defaults.set(data, forKey: "dailyLog")
            defaults.set(todayString(), forKey: "dailyLogDate")
        }
        if let data = try? encoder.encode(savedRecipes) {
            defaults.set(data, forKey: "savedRecipes")
        }
        defaults.set(cycleDay, forKey: "cycleDay")
        defaults.set(cycleLength, forKey: "cycleLength")
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - HealthKit connect flow

    func connectHealthKit() async {
        healthKitLoading = true
        healthKitError = nil
        do {
            try await HealthKitManager.shared.requestAuthorization()
            profile.healthKitConnected = true
            await loadCycleData()
        } catch {
            healthKitError = "Couldn't connect to Apple Health. You can try again from Settings."
        }
        healthKitLoading = false
        advance()
    }

    func loadCycleData() async {
        let (day, length) = await HealthKitManager.shared.fetchCycleData()
        cycleDay = day
        cycleLength = length
    }

    // MARK: - Navigation

    func advance() {
        switch screen {
        case .connect:        screen = .signupSymptoms
        case .signupSymptoms: screen = .signupDiet
        case .signupDiet:     screen = .signupNotes
        case .signupNotes:    screen = .home
        case .home:           break
        }
    }

    func back() {
        switch screen {
        case .signupDiet:     screen = .signupSymptoms
        case .signupNotes:    screen = .signupDiet
        default:              break
        }
    }
}
