import CoreGraphics

final class TrajectoryComponent: Component {
    let shape: PhysicsBody.Shape
    let size: CGSize
    var maxCollisions: Int

    let entity = Entity()
    var velocity: CGVector?
    var points: [CGPoint] = []

    init(shape: PhysicsBody.Shape, size: CGSize, maxCollisions: Int = 1) {
        self.shape = shape
        self.size = size
        self.maxCollisions = maxCollisions
    }
}
