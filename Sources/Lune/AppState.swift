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

    // Profile
    @Published var profile = Profile()

    // Cycle — demo defaults, real implementation reads HealthKit
    @Published var cycleDay: Int = 19
    @Published var cycleLength: Int = 28

    // Today's log (keyed by date string in production; single session here)
    @Published var dailyLog = DailyLog()

    @Published var savedRecipes: [Recipe] = []

    var phaseInfo: CyclePhaseInfo {
        cyclePhase(day: cycleDay, length: cycleLength)
    }

    // Navigation helpers
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
