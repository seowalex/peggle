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
            size = CGSize(width: max(size.width, 0.04), height: max(size.height, 0.04))
            physicsBody.size = size
        }
    }
    let physicsBody: PhysicsBody

    var imageName: String {
        ""
    }

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
