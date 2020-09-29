import Foundation
import Bow

/// Witness for the `Program<F, A>` data type. To be used in simulated Higher Kinded Types.
public final class ForProgram {}

/// Partial application of the `Program` type constructor, omitting the last parameter.
public final class ProgramPartial<F>: Kind<ForProgram, F> {}

/// Higher Kinded Type alias to improve readability.
public typealias ProgramOf<F, A> = Kind<ProgramPartial<F>, A>

/// Program is a type that, given any type constructor, is able to provide a Monad instance, that can be interpreted into a more restrictive one.
///
/// As opposed to `Free`, `Program` does not require `F` to be a functor, which means that evaluation of `map` calls are deferred
/// and left for the later interpretation in another monad.
public final class Program<F, A>: ProgramOf<F, A> {
    let asFree: Free<CoyonedaPartial<F>, A>

    init(asFree: Free<CoyonedaPartial<F>, A>) {
        self.asFree = asFree
    }

    /// Safe downcast.
    ///
    /// - Parameter fa: Value in the higher-kind form.
    /// - Returns: Value cast to `Program`.
    public static func fix(_ fa: ProgramOf<F, A>) -> Program<F, A> {
        return fa as! Program<F, A>
    }

    /// Lifts a value in the context of `F` into the `Program` context.
    ///
    /// - Parameter fa: A value in the context of `F`.
    /// - Returns: A `Program` value.
    public static func liftF(_ fa: Kind<F, A>) -> Program<F, A> {
        return fa |> (Coyoneda.liftCoyoneda
                        >>> Free.liftF
                        >>> Program.init)
    }

    /// Interprets this `Program` value into the provided Monad.
    ///
    /// - Parameter f: A natural transformation from `F` into the desired Monad.
    /// - Returns: A value in the interpreted Monad.
    public func foldMapK<M: Monad>(_ f: FunctionK<F, M>) -> Kind<M, A> {
        f.transformAndReduce.free().invoke(asFree)^.run()
    }
}

/// Safe downcast.
///
/// - Parameter fa: Value in higher-kind form.
/// - Returns: Value cast to `Program`.
public postfix func ^<F, A>(_ fa: ProgramOf<F, A>) -> Program<F, A> {
    return Program.fix(fa)
}

public extension Program where F: Monad {
    /// Folds this program structure using the same Monad.
    ///
    /// - Returns: Folded value.
    func run() -> Kind<F, A> {
        self.foldMapK(FunctionK<F, F>.id)
    }
}

extension ProgramPartial: Functor {
    public static func map<A, B>(_ fa: Kind<ProgramPartial<F>, A>, _ f: @escaping (A) -> B) -> Kind<ProgramPartial<F>, B> {
        Program(asFree: fa^.asFree.map(f)^)
    }
}

extension ProgramPartial: Applicative {
    public static func pure<A>(_ a: A) -> Kind<ProgramPartial<F>, A> {
        Program(asFree: Free<CoyonedaPartial<F>, A>.pure(a)^)
    }

    public static func ap<A, B>(_ ff: Kind<ProgramPartial<F>, (A) -> B>, _ fa: Kind<ProgramPartial<F>, A>) -> Kind<ProgramPartial<F>, B> {
        Program(asFree: ff^.asFree.ap(fa^.asFree)^)
    }
}

extension ProgramPartial: Monad {
    public static func flatMap<A, B>(_ fa: Kind<ProgramPartial<F>, A>, _ f: @escaping (A) -> Kind<ProgramPartial<F>, B>) -> Kind<ProgramPartial<F>, B> {
        Program(asFree: fa^.asFree.flatMap { f($0)^.asFree }^)
    }

    public static func tailRecM<A, B>(_ a: A, _ f: @escaping (A) -> Kind<ProgramPartial<F>, Either<A, B>>) -> Kind<ProgramPartial<F>, B> {
        Program(asFree: Free.tailRecM(a, { f($0)^.asFree })^)
    }
}
