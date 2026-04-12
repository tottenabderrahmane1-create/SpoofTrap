import SwiftUI

enum FirstLaunchDisclaimer {
    /// Shown once on first launch before onboarding. Calm copy: responsibility + local rules, not legal advice.
    static let paragraph = """
SpoofTrap helps you run Roblox when your network makes that harder. By continuing, you agree you are responsible for following the laws and rules that apply to you—including your school or employer’s policies, your internet provider’s terms, and Roblox’s Terms of Use—and that you will only use the app where you are allowed to. This is not legal advice; if you are unsure, check with a parent, guardian, or other appropriate person before you continue.
"""

    static let userDefaultsKey = "SpoofTrap.firstLaunchDisclaimerSeen"
}

struct FirstLaunchDisclaimerView: View {
    @Binding var isComplete: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.14)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan.opacity(0.9), .blue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    VStack(spacing: 8) {
                        Text("Before you start")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Quick notice")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.cyan.opacity(0.75))
                    }
                    .opacity(appeared ? 1 : 0)

                    Text(FirstLaunchDisclaimer.paragraph)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 520)
                        .opacity(appeared ? 1 : 0)

                    Button {
                        UserDefaults.standard.set(true, forKey: FirstLaunchDisclaimer.userDefaultsKey)
                        withAnimation(.easeOut(duration: 0.35)) {
                            isComplete = true
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.5), Color.blue.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()
                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 36)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
        }
    }
}
