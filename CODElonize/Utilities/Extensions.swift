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
