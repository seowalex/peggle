import CoreGraphics

class Element {
    var position: CGPoint {
        didSet {
            physicsBody.position = position
        }
    }
    var rotation: CGFloat {
        didSet {
            physicsBody.rotation = rotation
        }
    }
    var size: CGSize {
        didSet {
            size = CGSize(width: max(0.04, size.width), height: max(0.04, size.height))
            physicsBody.size = size
        }
    }
    let physicsBody: PhysicsBody

    init(position: CGPoint, rotation: CGFloat, size: CGSize, physicsBody: PhysicsBody) {
        self.position = position
        self.rotation = rotation
        self.size = size
        self.physicsBody = physicsBody
    }
}

extension Element: Hashable {
   static func == (lhs: Element, rhs: Element) -> Bool {
       ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
   }

   func hash(into hasher: inout Hasher) {
       hasher.combine(ObjectIdentifier(self))
   }
}
