import CoreGraphics

extension CGAffineTransform {
    static func rotate(around point: CGPoint, by angle: CGFloat) -> CGAffineTransform {
        let translate = CGAffineTransform(translationX: point.x, y: point.y)
        let rotate = CGAffineTransform(rotationAngle: angle)

        return translate.inverted().concatenating(rotate).concatenating(translate)
    }
}
