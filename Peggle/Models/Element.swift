import CoreGraphics

class Element {
    static let minimumSize = CGSize(width: 0.04, height: 0.04)

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
            size = CGSize(width: max(size.width, Element.minimumSize.width),
                          height: max(size.height, Element.minimumSize.height))
            physicsBody.size = size
        }
    }

    var isOscillating: Bool
    var minCoefficient: CGFloat
    var maxCoefficient: CGFloat
    var frequency: CGFloat

    let physicsBody: PhysicsBody

    var imageName: String {
        ""
    }

    init(position: CGPoint, rotation: CGFloat, size: CGSize, isOscillating: Bool, minCoefficient: CGFloat,
         maxCoefficient: CGFloat, frequency: CGFloat, physicsBody: PhysicsBody) {
        self.position = position
        self.rotation = rotation
        self.size = size

        self.isOscillating = isOscillating
        self.minCoefficient = minCoefficient
        self.maxCoefficient = maxCoefficient
        self.frequency = frequency

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
