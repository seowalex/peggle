import CoreGraphics

extension CGVector {
    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func * (lhs: CGFloat, rhs: CGVector) -> CGVector {
        rhs * lhs
    }

    static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }

    // swiftlint:disable shorthand_operator
    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs - rhs
    }
    // swiftlint:enable shorthand_operator
}

extension CGVector {
    func magnitude() -> CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    func normalized() -> CGVector {
        self / magnitude()
    }

    func dot(_ vector: CGVector) -> CGFloat {
        dx * vector.dx + dy * vector.dy
    }
}
