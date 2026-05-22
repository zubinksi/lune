import SwiftUI

enum AppScreen {
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

    // Derived from HealthKit after authorization; sensible defaults until then
    @Published var cycleDay: Int = 1
    @Published var cycleLength: Int = 28
    @Published var healthKitLoading: Bool = false
    @Published var healthKitError: String? = nil

    @Published var dailyLog = DailyLog()
    @Published var savedRecipes: [Recipe] = []

    var phaseInfo: CyclePhaseInfo {
        cyclePhase(day: cycleDay, length: cycleLength)
    }

    // MARK: - HealthKit connect flow
    // Called from ConnectScreen "Connect Apple Health" button.
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

    // Silently refresh cycle data (e.g. on app foreground).
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
