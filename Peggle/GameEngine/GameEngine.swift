import Combine
import CoreGraphics
import Foundation

final class GameEngine {
    var gameState: StateComponent? {
        entityManager.getComponent(StateComponent.self, for: gameEntity)
    }
    var renderComponents: [RenderComponent] {
        entityManager.getComponents(RenderComponent.self)
    }

    private let entityManager = EntityManager()
    private let physicsWorld = PhysicsWorld()

    private let entityFactory: EntityFactory
    private let systems: [System]

    private var gameEntity: Entity
    private var bucketEntity: Entity!

    private var componentsCancellable: AnyCancellable?
    private var collisionCancellable: AnyCancellable?

    init(elements: [Element]) {
        entityFactory = EntityFactory(entityManager: entityManager)
        systems = [
            StateSystem(entityManager: entityManager),
            OscillateSystem(entityManager: entityManager),
            PowerSystem(entityManager: entityManager),
            AimSystem(entityManager: entityManager),
            TrajectorySystem(entityManager: entityManager),
            ScoreSystem(entityManager: entityManager),
            ClearSystem(entityManager: entityManager),
            PhysicsSystem(entityManager: entityManager),
            RenderSystem(entityManager: entityManager)
        ]

        gameEntity = Entity()
        entityManager.addComponent(StateComponent(orangePegsCount: elements.compactMap { $0 as? Peg }
                                                    .filter { $0.color == .orange }.count),
                                   to: gameEntity)
        createEntities(elements: elements)

        componentsCancellable = entityManager.$components.sink { [weak self] _ in
            guard let bodies = self?.entityManager.getComponents(PhysicsComponent.self).map({ $0.physicsBody }) else {
                return
            }

            self?.physicsWorld.bodies = bodies
        }

        collisionCancellable = physicsWorld.collisionPublisher.sink { [weak self] bodyA, bodyB in
            guard let entities = self?.entityManager.getEntities(for: PhysicsComponent.self) else {
                return
            }

            for entity in entities {
                guard let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                      physicsComponent.physicsBody === bodyA || physicsComponent.physicsBody === bodyB else {
                    continue
                }

                // Activate powers
                if let powerComponent = self?.entityManager.getComponent(PowerComponent.self, for: entity) {
                    powerComponent.isActivated = true
                }

                // Light pegs
                if let scoreComponent = self?.entityManager.getComponent(ScoreComponent.self, for: entity) {
                    scoreComponent.isScored = true
                }

                // Check for ball entering bucket
                if let clearComponent = self?.entityManager.getComponent(ClearComponent.self, for: entity),
                   let bucket = self?.bucketEntity,
                   let bucketBody = self?.entityManager.getComponent(PhysicsComponent.self, for: bucket)?.physicsBody,
                   let powerComponents = self?.entityManager.getComponents(PowerComponent.self),
                   clearComponent.willClear == false
                    && (bucketBody === bodyA || bucketBody === bodyB)
                    && !powerComponents.contains(where: { $0.power == .spookyBall && $0.isActivated == true
                                                && $0.turnsRemaining == 1 }) {
                    clearComponent.willClear = true
                    print("ball entered bucket")
                }
            }
        }
    }

    func createEntities(elements: [Element]) {
        entityFactory.createWall(position: CGPoint(x: 0.5, y: -0.2), size: CGSize(width: 1, height: 0.4))
        entityFactory.createWall(position: CGPoint(x: -0.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))
        entityFactory.createWall(position: CGPoint(x: 1.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))

        entityFactory.createCannon(position: CGPoint(x: 0.5, y: 0.07))
        bucketEntity = entityFactory.createBucket(position: CGPoint(x: 0.5, y: 1.37),
                                                  startPoint: CGPoint(x: 0.12, y: 1.37),
                                                  endPoint: CGPoint(x: 0.88, y: 1.37),
                                                  frequency: 0.2)

        let greenPegs = elements.compactMap { $0 as? Peg }.filter { $0.color == .blue }.shuffled().prefix(2)

        for element in elements.filter({ element in !greenPegs.contains { $0 === element } }) {
            let position = element.position.applying(CGAffineTransform(translationX: 0, y: 0.3))

            if let peg = element as? Peg {
                entityFactory.createPeg(position: position,
                                        color: peg.color,
                                        imageName: peg.imageName,
                                        rotation: element.rotation,
                                        size: element.size,
                                        isOscillating: element.isOscillating,
                                        minCoefficient: element.minCoefficient,
                                        maxCoefficient: element.maxCoefficient,
                                        frequency: element.frequency)
            } else if element is Block {
                entityFactory.createBlock(position: position,
                                          rotation: element.rotation,
                                          size: element.size,
                                          isOscillating: element.isOscillating,
                                          minCoefficient: element.minCoefficient,
                                          maxCoefficient: element.maxCoefficient,
                                          frequency: element.frequency)
            }
        }

        for peg in greenPegs {
            let pegEntity = entityFactory.createPeg(position: peg.position.applying(CGAffineTransform(translationX: 0,
                                                                                                      y: 0.3)),
                                                    color: .green,
                                                    imageName: "peg-green",
                                                    rotation: peg.rotation,
                                                    size: peg.size,
                                                    isOscillating: peg.isOscillating,
                                                    minCoefficient: peg.minCoefficient,
                                                    maxCoefficient: peg.maxCoefficient,
                                                    frequency: peg.frequency)
            entityManager.addComponent(PowerComponent(power: .spaceBlast), to: pegEntity)
        }
    }

    func onDrag(position: CGPoint) {
        guard entityManager.getComponents(ClearComponent.self).isEmpty else {
            return
        }

        let aimComponents = entityManager.getComponents(AimComponent.self)

        for aimComponent in aimComponents {
            aimComponent.target = position
        }
    }

    func onDragEnd(position: CGPoint) {
        guard entityManager.getComponents(ClearComponent.self).isEmpty else {
            return
        }

        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let trajectoryComponent = entityManager.getComponent(TrajectoryComponent.self, for: entity),
                  let velocity = aimComponent.velocity else {
                continue
            }

            entityFactory.createBall(position: aimComponent.position,
                                     velocity: velocity,
                                     physicsSpeed: physicsWorld.speed)

            aimComponent.target = nil
            trajectoryComponent.points = []
        }
    }

    func updateTrajectories(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: TrajectoryComponent.self)

        for entity in entities {
            guard let trajectoryComponent = entityManager.getComponent(TrajectoryComponent.self, for: entity),
                  let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let velocity = aimComponent.velocity else {
                continue
            }

            trajectoryComponent.points = physicsWorld
                .getTrajectoryPoints(body: PhysicsBody(shape: trajectoryComponent.shape,
                                                       size: trajectoryComponent.size,
                                                       position: aimComponent.position,
                                                       velocity: velocity),
                                     deltaTime: seconds,
                                     maxCollisions: trajectoryComponent.maxCollisions)
        }
    }

    func updateScore() {
        let scoreComponents = entityManager.getComponents(ScoreComponent.self)
    }

    func update(deltaTime seconds: CGFloat) {
        physicsWorld.update(deltaTime: seconds)
        updateTrajectories(deltaTime: seconds)

        for system in systems {
            system.update(deltaTime: seconds)
        }

        updateScore()
    }
}
