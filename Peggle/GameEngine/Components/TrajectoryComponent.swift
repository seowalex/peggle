import CoreGraphics

final class TrajectoryComponent: Component {
    let shape: PhysicsBody.Shape
    let size: CGSize
    
    let entity = Entity()
    var velocity: CGVector?
    var points: [CGPoint] = []

    init(shape: PhysicsBody.Shape, size: CGSize) {
        self.shape = shape
        self.size = size
    }
}
