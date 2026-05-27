import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var refreshed = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 80)

                    // MARK: Profile
                    sectionLabel("Profile")
                    Spacer().frame(height: 10)

                    Eyebrow("Your name")
                    Spacer().frame(height: 8)
                    TextField("e.g. Genesha", text: $appState.profile.name)
                        .font(LFont.body(15))
                        .foregroundColor(.lInk)
                        .padding(18)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.lRule, lineWidth: 1))

                    rule(40)

                    // MARK: Symptoms
                    sectionLabel("What to soften")
                    Spacer().frame(height: 6)
                    BodyText(text: "Meal suggestions are shaped around easing these.", size: 13)
                    Spacer().frame(height: 16)

                    FlowLayout(spacing: 8) {
                        ForEach(kSymptoms, id: \.self) { s in
                            ChipButton(label: s, selected: appState.profile.symptoms.contains(s)) {
                                toggle(&appState.profile.symptoms, item: s)
                            }
                        }
                    }

                    rule(40)

                    // MARK: Diet
                    sectionLabel("How you eat")
                    Spacer().frame(height: 6)
                    BodyText(text: "Restrictions and dietary preferences.", size: 13)
                    Spacer().frame(height: 16)

                    FlowLayout(spacing: 8) {
                        ForEach(kDiets, id: \.self) { d in
                            ChipButton(label: d, selected: appState.profile.diet.contains(d)) {
                                toggle(&appState.profile.diet, item: d)
                            }
                        }
                    }

                    rule(40)

                    // MARK: Cooking style
                    sectionLabel("Your palate")
                    Spacer().frame(height: 6)
                    BodyText(text: "Shapes the flavour and style of every recipe Ona suggests.", size: 13)
                    Spacer().frame(height: 16)

                    FlowLayout(spacing: 8) {
                        ForEach(kCookingStyles, id: \.self) { s in
                            ChipButton(label: s, selected: appState.profile.cookingStyles.contains(s)) {
                                toggle(&appState.profile.cookingStyles, item: s)
                            }
                        }
                    }

                    Spacer().frame(height: 16)

                    ZStack(alignment: .topLeading) {
                        if appState.profile.cookingStyleNotes.isEmpty {
                            Text("e.g. I love Ottolenghi, always come back to tahini and lemon…")
                                .font(LFont.body(14))
                                .foregroundColor(.lInk3)
                                .italic()
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $appState.profile.cookingStyleNotes)
                            .font(LFont.body(14))
                            .foregroundColor(.lInk)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 90)
                    }
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lRule, lineWidth: 1))

                    rule(40)

                    // MARK: Refresh meals
                    sectionLabel("Today's nourishment")
                    Spacer().frame(height: 6)
                    BodyText(text: "Updated preferences will apply tomorrow. Tap below to regenerate today's meals now.", size: 13)
                    Spacer().frame(height: 16)

                    Button {
                        appState.clearNourishmentCache()
                        refreshed = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: refreshed ? "checkmark" : "arrow.clockwise")
                                .font(.system(size: 13, weight: .regular))
                            Text(refreshed ? "Will refresh on home screen" : "Refresh today's meals")
                                .font(LFont.body(14))
                        }
                        .foregroundColor(refreshed ? .lSageDeep : .lInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.lRule, lineWidth: 1))
                    }
                    .animation(.easeInOut(duration: 0.2), value: refreshed)
                    .disabled(refreshed)

                    rule(40)

                    // MARK: Cycle tracking source
                    sectionLabel("Cycle tracking")
                    Spacer().frame(height: 6)

                    if appState.profile.healthKitConnected {
                        // HealthKit connected state
                        BodyText(text: "Your cycle data comes from Apple Health.", size: 13)
                        Spacer().frame(height: 16)

                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "ff5e6e"), Color(hex: "ff2d55")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Health")
                                    .font(LFont.body(14, weight: .medium))
                                    .foregroundColor(.lInk)
                                Text("Cycle tracking · read only")
                                    .font(LFont.body(12))
                                    .foregroundColor(.lInk3)
                            }

                            Spacer()

                            Text("ACTIVE")
                                .font(LFont.mono(9.5))
                                .tracking(1.2)
                                .foregroundColor(.lSageDeep)
                        }
                        .padding(16)
                        .cardStyle()

                        Spacer().frame(height: 14)

                        Button {
                            appState.profile.healthKitConnected = false
                        } label: {
                            Text("Switch to manual entry")
                                .font(LFont.body(13))
                                .foregroundColor(.lInk2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.lPaper)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.lRule, lineWidth: 1))
                        }
                    } else {
                        // Manual entry
                        BodyText(text: "Enter your cycle details manually. Ona uses these to estimate where you are in your cycle.", size: 13)
                        Spacer().frame(height: 16)

                        Eyebrow("Average cycle length")
                        Spacer().frame(height: 8)

                        HStack {
                            Button {
                                if appState.profile.manualCycleLength > 21 {
                                    appState.profile.manualCycleLength -= 1
                                    appState.computeCycleDayFromManual()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.lInk)
                                    .frame(width: 34, height: 34)
                                    .background(Color.lPaper)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                            }

                            Text("\(appState.profile.manualCycleLength) days")
                                .font(LFont.display(20))
                                .foregroundColor(.lInk)
                                .frame(minWidth: 80, alignment: .center)

                            Button {
                                if appState.profile.manualCycleLength < 40 {
                                    appState.profile.manualCycleLength += 1
                                    appState.computeCycleDayFromManual()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.lInk)
                                    .frame(width: 34, height: 34)
                                    .background(Color.lPaper)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

                        Spacer().frame(height: 14)

                        Eyebrow("Reference menstruation date")
                        Spacer().frame(height: 8)
                        BodyText(text: "The first day of a recent period. Ona uses this as a reference point to calculate your current cycle day.", size: 12)
                        Spacer().frame(height: 10)

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { appState.profile.referencePeriodDate ?? Date() },
                                set: { appState.profile.referencePeriodDate = $0; appState.computeCycleDayFromManual() }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Color.lPlum)
                        .padding(16)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

                        Spacer().frame(height: 14)

                        Button {
                            Task { await appState.connectHealthKit() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "ff2d55"))
                                Text("Switch to Apple Health")
                                    .font(LFont.body(13))
                                    .foregroundColor(.lInk2)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.lPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.lRule, lineWidth: 1))
                        }
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 24)
            }

            // Top bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(LFont.display(22))
                        .foregroundColor(.lInk)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(LFont.body(15, weight: .medium))
                        .foregroundColor(.lPlum)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lCream)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.lRule, lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(Color.lCream)
        }
        .presentationBackground(Color.lCream)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(LFont.display(20))
            .foregroundColor(.lInk)
    }

    private func rule(_ spacing: CGFloat) -> some View {
        Group {
            Spacer().frame(height: spacing)
            Divider().background(Color.lRule)
            Spacer().frame(height: spacing)
        }
    }

    private func toggle(_ list: inout [String], item: String) {
        if list.contains(item) {
            list.removeAll { $0 == item }
        } else {
            list.append(item)
        }
    }
}
