import CoreGraphics

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
        rhs * lhs
    }

    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }

    // swiftlint:disable shorthand_operator
    static func *= (lhs: inout CGSize, rhs: CGFloat) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout CGSize, rhs: CGFloat) {
        lhs = lhs / rhs
    }
    // swiftlint:enable shorthand_operator
}
