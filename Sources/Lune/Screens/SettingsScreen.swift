import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFocused: Bool
    @State private var refreshed = false
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    @State private var apiKeyVisible = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea()

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
                    BodyText(text: "Restrictions, preferences, what you want more of.", size: 13)
                    Spacer().frame(height: 16)

                    FlowLayout(spacing: 8) {
                        ForEach(kDiets, id: \.self) { d in
                            ChipButton(label: d, selected: appState.profile.diet.contains(d)) {
                                toggle(&appState.profile.diet, item: d)
                            }
                        }
                    }

                    rule(40)

                    // MARK: Notes
                    sectionLabel("Anything else")
                    Spacer().frame(height: 6)
                    BodyText(text: "Allergies, cravings, things you'd love more of.", size: 13)
                    Spacer().frame(height: 16)

                    ZStack(alignment: .topLeading) {
                        if appState.profile.notes.isEmpty {
                            Text("e.g. I can't do anything too heavy in the morning…")
                                .font(LFont.body(15))
                                .foregroundColor(.lInk3)
                                .italic()
                                .padding(18)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $appState.profile.notes)
                            .font(LFont.body(15))
                            .foregroundColor(.lInk)
                            .scrollContentBackground(.hidden)
                            .padding(18)
                            .frame(minHeight: 140)
                            .focused($notesFocused)
                    }
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
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

                    // MARK: API Key
                    sectionLabel("AI Recommendations")
                    Spacer().frame(height: 6)
                    BodyText(text: "Your Anthropic API key powers daily nourishment and recipe suggestions. It's stored only on this device.", size: 13)
                    Spacer().frame(height: 16)

                    HStack(spacing: 0) {
                        Group {
                            if apiKeyVisible {
                                TextField("sk-ant-...", text: $apiKey)
                            } else {
                                SecureField("sk-ant-...", text: $apiKey)
                            }
                        }
                        .font(LFont.body(14))
                        .foregroundColor(.lInk)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiKey) { _, val in
                            UserDefaults.standard.set(val.trimmingCharacters(in: .whitespaces), forKey: "anthropicAPIKey")
                        }

                        Button {
                            apiKeyVisible.toggle()
                        } label: {
                            Image(systemName: apiKeyVisible ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(.lInk3)
                                .padding(.leading, 10)
                        }
                    }
                    .padding(16)
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(apiKey.isEmpty ? Color.lRed.opacity(0.4) : Color.lRule, lineWidth: 1))

                    if apiKey.isEmpty {
                        Text("Add your key to enable AI features.")
                            .font(LFont.body(12))
                            .foregroundColor(.lRed.opacity(0.7))
                            .padding(.top, 6)
                    } else {
                        Text("Key saved ✓")
                            .font(LFont.body(12))
                            .foregroundColor(.lSageDeep)
                            .padding(.top, 6)
                    }

                    rule(40)

                    // MARK: HealthKit
                    sectionLabel("Apple Health")
                    Spacer().frame(height: 10)

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
                            Text(appState.profile.healthKitConnected ? "Connected" : "Not connected")
                                .font(LFont.body(14, weight: .medium))
                                .foregroundColor(.lInk)
                            Text("Cycle tracking · read only")
                                .font(LFont.body(12))
                                .foregroundColor(.lInk3)
                        }

                        Spacer()

                        if appState.profile.healthKitConnected {
                            Text("ACTIVE")
                                .font(LFont.mono(9.5))
                                .tracking(1.2)
                                .foregroundColor(.lSageDeep)
                        } else {
                            Button {
                                Task { await appState.connectHealthKit() }
                            } label: {
                                Text("Connect")
                                    .font(LFont.body(13, weight: .medium))
                                    .foregroundColor(.lCream)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.lPlum)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 50)
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
                    notesFocused = false
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
            .padding(.horizontal, 50)
            .padding(.top, 20)
            .background(
                Color.lCream
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.lInk.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
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
