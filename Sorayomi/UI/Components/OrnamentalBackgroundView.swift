import SwiftUI

/// Shared atmospheric background used on the refreshed primary screens.
struct SorayomiOrnamentalBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.sorayomiBackground,
                    Color.sorayomiPaper,
                    Color.sorayomiBackground,
                    Color.sorayomiFortuneGradientEnd.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.sorayomiGlow.opacity(0.30),
                    Color.sorayomiGlow.opacity(0.0)
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 260
            )
            .offset(x: 40, y: -80)

            RadialGradient(
                colors: [
                    Color.sorayomiSecondary.opacity(0.18),
                    Color.sorayomiSecondary.opacity(0.0)
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 220
            )
            .offset(x: -90, y: -20)

            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(Color.sorayomiPrimary.opacity(0.05))
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(16))
                .offset(x: -150, y: 250)
                .blur(radius: 20)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(Color.sorayomiAccent.opacity(0.07))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-14))
                .offset(x: 150, y: 330)
                .blur(radius: 22)

            VStack {
                HStack {
                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        .frame(width: 140, height: 140)
                        .blur(radius: 1)
                        .offset(x: -30, y: -30)

                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()

                    Circle()
                        .stroke(Color.sorayomiSecondary.opacity(0.20), lineWidth: 1)
                        .frame(width: 180, height: 180)
                        .blur(radius: 1)
                        .offset(x: 30, y: 20)
                }
            }
            .padding(.horizontal, 12)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SorayomiOrnamentalBackground()
}
