import CoreGraphics

extension CGRect {
    func rotate(around point: CGPoint, by angle: CGFloat) -> CGRect {
        applying(.rotate(around: point, by: angle))
    }

    func rotate(by angle: CGFloat) -> CGRect {
        rotate(around: CGPoint(x: midX, y: midY), by: angle)
    }
}
