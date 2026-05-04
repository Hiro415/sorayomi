import SwiftUI

/// Shared atmospheric background used on the refreshed primary screens.
/// Sizes are proportional to screen width for iPhone SE 〜 iPad Pro 12.9".
struct SorayomiOrnamentalBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let sizes = RevealSizeProvider(availableWidth: w)

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
                    endRadius: w * 0.65
                )
                .offset(x: w * 0.1, y: -80)

                RadialGradient(
                    colors: [
                        Color.sorayomiSecondary.opacity(0.18),
                        Color.sorayomiSecondary.opacity(0.0)
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: w * 0.55
                )
                .offset(x: w * -0.23, y: -20)

                RoundedRectangle(cornerRadius: 60, style: .continuous)
                    .fill(Color.sorayomiPrimary.opacity(0.05))
                    .frame(width: sizes.ornamentalLarge, height: sizes.ornamentalLarge)
                    .rotationEffect(.degrees(16))
                    .offset(x: w * -0.38, y: 250)
                    .blur(radius: 20)

                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .fill(Color.sorayomiAccent.opacity(0.07))
                    .frame(width: sizes.ornamentalLarge, height: sizes.ornamentalLarge)
                    .rotationEffect(.degrees(-14))
                    .offset(x: w * 0.38, y: 330)
                    .blur(radius: 22)

                VStack {
                    HStack {
                        Circle()
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                            .frame(width: sizes.ornamentalSmall * 0.78, height: sizes.ornamentalSmall * 0.78)
                            .blur(radius: 1)
                            .offset(x: -30, y: -30)

                        Spacer()
                    }

                    Spacer()

                    HStack {
                        Spacer()

                        Circle()
                            .stroke(Color.sorayomiSecondary.opacity(0.20), lineWidth: 1)
                            .frame(width: sizes.ornamentalSmall, height: sizes.ornamentalSmall)
                            .blur(radius: 1)
                            .offset(x: 30, y: 20)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SorayomiOrnamentalBackground()
}
