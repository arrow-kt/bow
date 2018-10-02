import Foundation

public typealias Proc<A> = (Callback<A>) throws -> Unit
public typealias Callback<A> = (Either<Error, A>) -> Unit

public protocol Async : MonadDefer {
    func runAsync<A>(_ fa : @escaping Proc<A>) -> Kind<F, A>
}

public func runAsync<F, A, AsyncC>(_ async : AsyncC, _ f : @escaping () throws -> A) -> Kind<F, A> where AsyncC : Async, AsyncC.F == F {
    return async.runAsync { callback in
        do {
            callback(Either<Error, A>.right(try f()))
        } catch {
            callback(Either<Error, A>.left(error))
        }
    }
}

public func runAsyncUnsafe<F, A, AsyncC>(_ asyncContext : AsyncC, _ f : @escaping () -> Either<Error, A>) -> Kind<F, A> where AsyncC : Async, AsyncC.F == F {
    return asyncContext.runAsync { callback in callback(f()) }
}
