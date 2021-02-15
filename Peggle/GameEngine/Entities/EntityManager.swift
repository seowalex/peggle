import Combine

final class EntityManager: ObservableObject {
    @Published private(set) var components: [String: [Entity: Component]] = [:]

    func removeEntity(_ entity: Entity) {
        for key in components.keys {
            components[key]?[entity] = nil
        }
    }

    func getEntities<T: Component>(for type: T.Type) -> [Entity] {
        guard let keys = components[String(describing: type)]?.keys else {
            return []
        }

        return Array(keys)
    }

    func addComponent<T: Component>(_ component: T, to entity: Entity) {
        components[String(describing: type(of: component)), default: [:]][entity] = component
    }

    func getComponent<T: Component>(_ type: T.Type, for entity: Entity) -> T? {
        components[String(describing: type)]?[entity] as? T
    }

    func getComponents<T: Component>(_ type: T.Type) -> [T] {
        guard let values = components[String(describing: type)]?.values,
              let components = Array(values) as? [T] else {
            return []
        }

        return components
    }
}
