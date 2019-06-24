import Bow

// MARK: Optics extensions
public extension Ior {
    /// Provides an Iso to go from/to this type to its `Kind` version.
    static var fixIso: Iso<Ior<A, B>, IorOf<A, B>> {
        return Iso(get: id, reverseGet: Ior.fix)
    }
    
    static var fold: Fold<Ior<A, B>, B> {
        return fixIso + foldK
    }
    
    static var traversal: Traversal<Ior<A, B>, B> {
        return fixIso + traversalK
    }
}

// MARK: Instance of `Each` for `Ior`
extension Ior: Each {
    public typealias EachFoci = B
    
    public static var each: Traversal<Ior<A, B>, B> {
        return traversal
    }
}
