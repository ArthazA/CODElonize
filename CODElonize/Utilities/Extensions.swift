//
//  Extensions.swift
//  CODElonize
//
//  Created by Arthaz's MacBook on 05/07/26.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Rounds only the specified corners of a view.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// A shape that rounds only specific corners of a rectangle.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension LinearGradient {
    static let themeBackground = LinearGradient(
        colors: [.themeTeal, .themeDarkTeal],
        startPoint: .top,
        endPoint: .bottom
    )
    static let themeButton = LinearGradient(
        colors: [.themeOrange, .themeDarkOrange],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct AppTitleText: View {
    let text: String
    var color: Color = .themeDarkTeal
    var size: CGFloat = 56

    var body: some View {
        StrokedText(
            text: text,
            font: .custom("Luckiest Guy", size: size),
            fillColor: color,
            strokeColor: .themeDarkTeal,
            strokeWidth: 2
        )
    }
}

struct AppSubtitleText: View {
    let text: String
    var color: Color = .white
    var strokeWidth: CGFloat = 1

    var body: some View {
        StrokedText(
            text: text,
            font: .system(size: 20, weight: .bold, design: .rounded),
            fillColor: color,
            strokeColor: .themeDarkTeal,
            strokeWidth: strokeWidth
        )
    }
}

struct StrokedText: View {
    let text: String
    var font: Font
    var fillColor: Color
    var strokeColor: Color = .themeDarkTeal
    var strokeWidth: CGFloat = 2

    var body: some View {
        ZStack {
            ForEach(directions, id: \.self) { direction in
                Text(text)
                    .font(font)
                    .foregroundColor(strokeColor)
                    .offset(x: direction.x * strokeWidth, y: direction.y * strokeWidth)
            }
            Text(text)
                .font(font)
                .foregroundColor(fillColor)
        }
    }

    private var directions: [CGPoint] {
        [
            CGPoint(x: -1, y: -1), CGPoint(x: 0, y: -1), CGPoint(x: 1, y: -1),
            CGPoint(x: -1, y: 0),                        CGPoint(x: 1, y: 0),
            CGPoint(x: -1, y: 1),  CGPoint(x: 0, y: 1),  CGPoint(x: 1, y: 1)
        ]
    }
}
