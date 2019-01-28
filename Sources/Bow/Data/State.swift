import Foundation

public typealias StatePartial<S> = StateTPartial<ForId, S>
public typealias StateOf<S, A> = StateT<ForId, S, A>

public class State<S, A> : StateOf<S, A> {
    public static func fix(_ value : StateOf<S, A>) -> State<S, A> {
        return value as! State<S, A>
    }
    
    public init(_ run : @escaping (S) -> (S, A)) {
        super.init(Id.pure({ s in Id.pure(run(s)) }))
    }
}

public extension State {
    public static func functor() -> StateT<ForId, S, A>.FunctorInstance<ForId, S, Id<A>.FunctorInstance> {
        return StateT<ForId, S, A>.functor(Id<A>.functor())
    }
    
    public static func applicative() -> StateT<ForId, S, A>.ApplicativeInstance<ForId, S, Id<A>.MonadInstance> {
        return StateT<ForId, S, A>.applicative(Id<A>.monad())
    }
    
    public static func monad() -> StateT<ForId, S, A>.MonadInstance<ForId, S, Id<A>.MonadInstance> {
        return StateT<ForId, S, A>.monad(Id<A>.monad())
    }
    
    public static func monadState() -> StateT<ForId, S, A>.MonadStateInstance<ForId, S, Id<A>.MonadInstance> {
        return StateT<ForId, S, A>.monadState(Id<A>.monad())
    }
}
