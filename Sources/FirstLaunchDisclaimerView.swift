import SwiftUI

enum FirstLaunchDisclaimer {
    static let paragraph = """
SpoofTrap is a privacy and anti-censorship tool. It restores your access to Roblox on networks where it has been blocked. SpoofTrap does not modify Roblox, does not interact with your Roblox account, and does not provide any in-game advantage.

You are responsible for ensuring that your use of this software complies with the laws of your country and the rules of any networks you connect to. Some jurisdictions restrict tools that bypass network controls. Use SpoofTrap only where you are authorized to do so.

By clicking ‘I Understand and Agree’ you confirm that you have read and accept these terms.
"""

    static let userDefaultsKey = "SpoofTrap.firstLaunchDisclaimerSeen"
}

struct FirstLaunchDisclaimerView: View {
    @Binding var isPresented: Bool
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

                        Text("Legal Notice")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.cyan.opacity(0.75))
                    }
                    .opacity(appeared ? 1 : 0)

                    ScrollView {
                        Text(FirstLaunchDisclaimer.paragraph)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 520)
                    }
                    .frame(maxHeight: 200)
                    .opacity(appeared ? 1 : 0)

                    Button {
                        UserDefaults.standard.set(true, forKey: FirstLaunchDisclaimer.userDefaultsKey)
                        isPresented = false
                    } label: {
                        Text("I Understand and Agree")
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
