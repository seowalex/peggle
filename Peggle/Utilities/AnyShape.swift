import SwiftUI

struct AnyShape: Shape {
    private let path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        path = shape.path
    }

    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}
