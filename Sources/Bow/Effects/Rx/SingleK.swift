import Foundation
import RxSwift

public class ForSingleK {}
public typealias SingleKOf<A> = Kind<ForSingleK, A>

public extension PrimitiveSequence where Trait == SingleTrait {
    public func k() -> SingleK<Element> {
        return SingleK<Element>(value: self)
    }
}

// There should be a better way to do this...
extension PrimitiveSequence {
    func blockingGet() -> Element? {
        var result : Element?
        var flag = false
        let _ = self.asObservable().subscribe(onNext: { element in
            if result == nil {
                result = element
            }
            flag = true
        }, onError: { _ in
            flag = true
        }, onCompleted: {
            flag = true
        }, onDisposed: {
            flag = true
        })
        while(!flag) {}
        return result
    }
}

public class SingleK<A> : SingleKOf<A> {
    public let value : Single<A>
    
    public static func fix(_ value : SingleKOf<A>) -> SingleK<A> {
        return value as! SingleK<A>
    }
    
    public static func pure(_ a : A) -> SingleK<A> {
        return Single.just(a).k()
    }
    
    public static func raiseError(_ error : Error) -> SingleK<A> {
        return Single<A>.error(error).k()
    }
    
    public static func from(_ fa : @escaping () -> A) -> SingleK<A> {
        return suspend { pure(fa()) }
    }
    
    public static func suspend(_ fa : @escaping () -> SingleKOf<A>) -> SingleK<A> {
        return Single.deferred { fa().fix().value }.k()
    }
    
    public static func async(_ fa : @escaping Proc<A>) -> SingleK<A> {
        return Single<A>.create { emitter in
            do {
                try fa { (either : Either<Error, A>) in
                    either.fold({ e in emitter(.error(e)) },
                                { a in emitter(.success(a)) })
                }
            } catch {}
            return Disposables.create()
        }.k()
    }
    
    public static func tailRecM<B>(_ a : A, _ f : @escaping (A) -> SingleKOf<Either<A, B>>) -> SingleK<B> {
        let either = f(a).fix().value.blockingGet()!
        return either.fold({ a in tailRecM(a, f) },
                           { b in Single.just(b).k() })
    }
    
    public init(value : Single<A>) {
        self.value = value
    }
    
    public func map<B>(_ f : @escaping (A) -> B) -> SingleK<B> {
        return value.map(f).k()
    }
    
    public func ap<B>(_ fa : SingleKOf<(A) -> B>) -> SingleK<B> {
        return flatMap { a in fa.fix().map { ff in ff(a) } }
    }
    
    public func flatMap<B>(_ f : @escaping (A) -> SingleKOf<B>) -> SingleK<B> {
        return value.flatMap { x in f(x).fix().value }.k()
    }
    
    public func handleErrorWith(_ f : @escaping (Error) -> SingleK<A>) -> SingleK<A> {
        return value.catchError { e in f(e).value }.k()
    }
    
    public func runAsync(_ callback : @escaping (Either<Error, A>) -> SingleKOf<Unit>) -> SingleK<Unit> {
        return value.flatMap { a in callback(Either.right(a)).fix().value }
            .catchError{ e in callback(Either.left(e)).fix().value }.k()
    }
    
    public func runAsyncCancellable(_ callback : @escaping (Either<Error, A>) -> SingleKOf<Unit>) -> SingleK<Disposable> {
        return Single<Disposable>.create { _ in
            return self.runAsync(callback).value.subscribe()
        }.k()
    }
}

public extension Kind where F == ForSingleK {
    public func fix() -> SingleK<A> {
        return SingleK<A>.fix(self)
    }
}

public extension SingleK {
    public static func functor() -> SingleKFunctor {
        return SingleKFunctor()
    }
    
    public static func applicative() -> SingleKApplicative {
        return SingleKApplicative()
    }
    
    public static func monad() -> SingleKMonad {
        return SingleKMonad()
    }
    
    public static func applicativeError() -> SingleKApplicativeError {
        return SingleKApplicativeError()
    }
    
    public static func monadError() -> SingleKMonadError {
        return SingleKMonadError()
    }
    
    public static func monadDefer() -> SingleKMonadDefer {
        return SingleKMonadDefer()
    }
    
    public static func async() -> SingleKAsync {
        return SingleKAsync()
    }
    
    public static func effect() -> SingleKEffect {
        return SingleKEffect()
    }
    
    public static func concurrentEffect() -> SingleKConcurrentEffect {
        return SingleKConcurrentEffect()
    }
}

public class SingleKFunctor : Functor {
    public typealias F = ForSingleK
    
    public func map<A, B>(_ fa: SingleKOf<A>, _ f: @escaping (A) -> B) -> SingleKOf<B> {
        return fa.fix().map(f)
    }
}

public class SingleKApplicative : SingleKFunctor, Applicative {
    public func pure<A>(_ a: A) -> SingleKOf<A> {
        return SingleK.pure(a)
    }
    
    public func ap<A, B>(_ fa: SingleKOf<A>, _ ff: SingleKOf<(A) -> B>) -> SingleKOf<B> {
        return fa.fix().ap(ff)
    }
}

public class SingleKMonad : SingleKApplicative, Monad {
    public func flatMap<A, B>(_ fa: Kind<ForSingleK, A>, _ f: @escaping (A) -> Kind<ForSingleK, B>) -> Kind<ForSingleK, B> {
        return fa.fix().flatMap(f)
    }
    
    public func tailRecM<A, B>(_ a: A, _ f: @escaping (A) -> Kind<ForSingleK, Either<A, B>>) -> Kind<ForSingleK, B> {
        return SingleK.tailRecM(a, f)
    }
}

public class SingleKApplicativeError : SingleKApplicative, ApplicativeError {
    public typealias E = Error
    
    public func raiseError<A>(_ e: Error) -> SingleKOf<A> {
        return SingleK.raiseError(e)
    }
    
    public func handleErrorWith<A>(_ fa: SingleKOf<A>, _ f: @escaping (Error) -> SingleKOf<A>) -> SingleKOf<A> {
        return fa.fix().handleErrorWith{ e in f(e).fix() }    }
}

public class SingleKMonadError : SingleKMonad, MonadError {
    public typealias E = Error
    
    public func raiseError<A>(_ e: Error) -> SingleKOf<A> {
        return SingleK.raiseError(e)
    }
    
    public func handleErrorWith<A>(_ fa: SingleKOf<A>, _ f: @escaping (Error) -> SingleKOf<A>) -> SingleKOf<A> {
        return fa.fix().handleErrorWith { e in f(e).fix() }
    }
}

public class SingleKMonadDefer : SingleKMonadError, MonadDefer {
    public func suspend<A>(_ fa: @escaping () -> SingleKOf<A>) -> SingleKOf<A> {
        return SingleK.suspend(fa)
    }
}

public class SingleKAsync : SingleKMonadDefer, Async {
    public func runAsync<A>(_ fa: @escaping ((Either<Error, A>) -> Unit) throws -> Unit) -> Kind<ForSingleK, A> {
        return SingleK.async(fa)
    }
}

public class SingleKEffect : SingleKAsync, Effect {
    public func runAsync<A>(_ fa: Kind<ForSingleK, A>, _ callback: @escaping (Either<Error, A>) -> Kind<ForSingleK, Unit>) -> Kind<ForSingleK, Unit> {
        return fa.fix().runAsync(callback)
    }
}

public class SingleKConcurrentEffect : SingleKEffect, ConcurrentEffect {
    public func runAsyncCancellable<A>(_ fa: Kind<ForSingleK, A>, _ callback: @escaping (Either<Error, A>) -> Kind<ForSingleK, Unit>) -> Kind<ForSingleK, Disposable> {
        return fa.fix().runAsyncCancellable(callback)
    }
}
