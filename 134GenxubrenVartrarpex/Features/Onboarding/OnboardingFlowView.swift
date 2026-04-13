//
//  OnboardingFlowView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page: Int = 0
    @State private var shapePulse: CGFloat = 0.92

    private let pageCount = 3

    var body: some View {
        ZStack {
            Color.clear
                .entertainmentAtmosphereBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        store.completeOnboarding()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.trailing, 4)
                }
                .entertainmentScreenPadding()
                .padding(.top, 8)

                TabView(selection: $page) {
                    onboardingPage(
                        title: "Playful challenges",
                        subtitle: "Explore handcrafted activities built for focus, creativity, and fun.",
                        illustration: { colorBurst }
                    )
                    .tag(0)
                    onboardingPage(
                        title: "Earn shining stars",
                        subtitle: "Perform well to collect up to three stars and open fresh levels.",
                        illustration: { starRibbon }
                    )
                    .tag(1)
                    onboardingPage(
                        title: "Grow your journey",
                        subtitle: "Track highlights, unlock tougher tiers, and celebrate milestones.",
                        illustration: { mountainPath }
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut(duration: 0.35), value: page)

                VStack(spacing: 12) {
                    if page > 0 {
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                page -= 1
                            }
                        } label: {
                            Text("Back")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(EntertainmentSecondaryButtonStyle())
                    }

                    Button {
                        if page < pageCount - 1 {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                page += 1
                            }
                        } else {
                            store.completeOnboarding()
                        }
                    } label: {
                        Text(page < pageCount - 1 ? "Continue" : "Get Started")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(EntertainmentPrimaryButtonStyle())
                }
                .entertainmentScreenPadding()
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                shapePulse = 1.06
            }
        }
    }

    private func onboardingPage(title: String, subtitle: String, illustration: @escaping () -> some View) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                illustration()
                    .frame(height: 220)
                    .scaleEffect(shapePulse)
                    .animation(.spring(response: 0.55, dampingFraction: 0.72), value: page)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .entertainmentCardChrome(cornerRadius: 24, elevated: true)
                    .padding(.top, 24)

                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .entertainmentScreenPadding()
            .padding(.bottom, 24)
        }
    }

    private var colorBurst: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<6 {
                var path = Path()
                let angle = Double(index) / 6 * Double.pi * 2
                let inner = 18 + CGFloat(index) * 4
                let outer = min(size.width, size.height) * 0.42
                path.move(to: center)
                path.addArc(center: center, radius: outer, startAngle: .radians(angle), endAngle: .radians(angle + .pi / 3), clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(Color.appPrimary.opacity(0.35 + Double(index) * 0.05)))
            }
            let ring = Path(ellipseIn: CGRect(x: center.x - 46, y: center.y - 46, width: 92, height: 92))
            context.stroke(ring, with: .color(Color.appAccent), lineWidth: 4)
        }
        .accessibilityHidden(true)
    }

    private var starRibbon: some View {
        Canvas { context, size in
            var ribbon = Path()
            ribbon.move(to: CGPoint(x: 24, y: size.height * 0.55))
            ribbon.addQuadCurve(to: CGPoint(x: size.width - 24, y: size.height * 0.42), control: CGPoint(x: size.width * 0.5, y: size.height * 0.2))
            context.stroke(ribbon, with: .color(Color.appAccent.opacity(0.85)), lineWidth: 6)

            for index in 0..<5 {
                let t = CGFloat(index) / 4
                let point = CGPoint(
                    x: 24 + (size.width - 48) * t,
                    y: (size.height * 0.55) * (1 - t * 0.22) + (size.height * 0.42) * (t * 0.22)
                )
                let star = starPath(center: point, radius: 14)
                context.fill(star, with: .color(Color.appPrimary))
            }
        }
        .accessibilityHidden(true)
    }

    private var mountainPath: some View {
        Canvas { context, size in
            var terrain = Path()
            terrain.move(to: CGPoint(x: 0, y: size.height))
            terrain.addLine(to: CGPoint(x: 0, y: size.height * 0.62))
            terrain.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.48), control: CGPoint(x: size.width * 0.45, y: size.height * 0.25))
            terrain.addLine(to: CGPoint(x: size.width, y: size.height))
            terrain.closeSubpath()
            context.fill(terrain, with: .color(Color.appSurface))

            var pathLine = Path()
            pathLine.move(to: CGPoint(x: 32, y: size.height * 0.78))
            pathLine.addQuadCurve(to: CGPoint(x: size.width - 40, y: size.height * 0.4), control: CGPoint(x: size.width * 0.52, y: size.height * 0.62))
            context.stroke(pathLine, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [10, 10]))
        }
        .accessibilityHidden(true)
    }

    private func starPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let points = 5
        for index in 0..<(points * 2) {
            let angle = CGFloat(index) / CGFloat(points * 2) * .pi * 2 - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
