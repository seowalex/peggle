import CoreGraphics

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }

    // swiftlint:disable shorthand_operator
    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs - rhs
    }
    // swiftlint:enable shorthand_operator
}

extension CGPoint {
    func rotate(around point: CGPoint, by angle: CGFloat) -> CGPoint {
        applying(.rotate(around: point, by: angle))
    }

    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y

        return sqrt(dx * dx + dy * dy)
    }

    func distance(to line: (CGPoint, CGPoint)) -> CGFloat {
        abs((line.1.x - line.0.x) * (line.0.y - y) - (line.0.x - x) * (line.1.y - line.0.y))
            / line.0.distance(to: line.1)
    }

    func angle(to point: CGPoint) -> CGFloat {
        atan2(point.y - y, point.x - x)
    }
}

extension CGPoint: Comparable {
    public static func < (lhs: CGPoint, rhs: CGPoint) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        } else {
            return lhs.y < rhs.y
        }
    }
}
