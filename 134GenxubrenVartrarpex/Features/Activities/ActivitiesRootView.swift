//
//  ActivitiesRootView.swift
//  134GenxubrenVartrarpex
//

import SwiftUI

struct ActivitiesRootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ActivityCatalogView { kind in
                path.append(ActivityFlowRoute.levels(kind))
            }
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ActivityFlowRoute.self) { route in
                switch route {
                case .levels(let kind):
                    ActivityLevelsView(path: $path, activity: kind)
                        .navigationTitle(kind.displayTitle)
                        .navigationBarTitleDisplayMode(.inline)
                case .session(let address):
                    ActivitySessionCoordinator(path: $path, address: address)
                        .navigationTitle("Session")
                        .navigationBarTitleDisplayMode(.inline)
                case .feedback(let outcome):
                    ActivityResultView(path: $path, outcome: outcome)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .entertainmentSceneBackground()
    }
}

private struct ActivityCatalogView: View {
    let onSelect: (ActivityKind) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose an experience")
                    .font(.title2.bold())
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Each path includes Easy, Normal, and Hard tiers with six linked stages apiece.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(ActivityKind.allCases, id: \.self) { kind in
                    Button {
                        onSelect(kind)
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ActivityGlyphIllustration(kind: kind)
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(kind.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(kind.detailDescription)
                                    .font(.footnote)
                                    .foregroundStyle(Color.appTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(16)
                        .entertainmentCardChrome(cornerRadius: 20, elevated: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .entertainmentScreenPadding()
            .padding(.vertical, 16)
        }
    }
}

private struct ActivityGlyphIllustration: View {
    let kind: ActivityKind

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            switch kind {
            case .colorSymphony:
                let cols = 2
                let rows = 2
                let w = rect.width / CGFloat(cols)
                let h = rect.height / CGFloat(rows)
                for r in 0..<rows {
                    for c in 0..<cols {
                        let tile = CGRect(x: rect.minX + CGFloat(c) * w, y: rect.minY + CGFloat(r) * h, width: w - 3, height: h - 3)
                        let path = Path(roundedRect: tile, cornerRadius: 6)
                        let colors = [Color.red, Color.blue, Color.green, Color.yellow]
                        context.fill(path, with: .color(colors[(r * cols + c) % colors.count].opacity(0.85)))
                    }
                }
            case .melodyMaker:
                var staff = Path()
                for index in 0..<5 {
                    let y = rect.minY + CGFloat(index + 1) / 6 * rect.height
                    staff.move(to: CGPoint(x: rect.minX, y: y))
                    staff.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
                context.stroke(staff, with: .color(Color.appTextSecondary.opacity(0.6)), lineWidth: 1.2)
                for index in 0..<4 {
                    let x = rect.minX + CGFloat(index + 1) / 5 * rect.width
                    let note = Path(ellipseIn: CGRect(x: x - 5, y: rect.midY - 8, width: 10, height: 8))
                    context.fill(note, with: .color(Color.appPrimary))
                }
            case .adventureSketch:
                let backdrop = Path(roundedRect: rect, cornerRadius: 10)
                context.fill(backdrop, with: .color(Color.appAccent.opacity(0.25)))
                let circle = Path(ellipseIn: CGRect(x: rect.midX - 18, y: rect.midY - 10, width: 22, height: 22))
                context.fill(circle, with: .color(Color.appPrimary.opacity(0.9)))
                var diamond = Path()
                diamond.move(to: CGPoint(x: rect.maxX - 16, y: rect.midY - 6))
                diamond.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.midY + 6))
                diamond.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.midY + 18))
                diamond.addLine(to: CGPoint(x: rect.maxX - 26, y: rect.midY + 6))
                diamond.closeSubpath()
                context.fill(diamond, with: .color(Color.appAccent))
            }
        }
        .accessibilityHidden(true)
    }
}
