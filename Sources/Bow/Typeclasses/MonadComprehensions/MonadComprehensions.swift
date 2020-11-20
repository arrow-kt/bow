class MonadComprehension<F: Monad> {
    static func buildBlock<A>(_ children: [BindingExpression<F>], yield: @escaping () -> A) -> Kind<F, A> {
        if let last = children.last {
            return Array(children.dropLast()).k()
                .foldRight(Eval.always { last.yield(yield) },
                { expression, partial in
                    Eval.always { expression.bind(partial) }
                }).value()
        } else {
            return F.pure(yield())
        }
    }
}

/// Monad comprehension.
///
/// Chains multiple binding expressions in imperative-style syntax by using the `flatMap` operation of the contextual `Monad`, and yields a final result.
///
/// - Parameters:
///   - instructions: A variable number of binding expressions.
///   - value: Value to be yield by the monad comprehension.
/// - Returns: An effect resulting from the chaining of all the effects included in this monad comprehension.
public func binding<F: Monad, A>(
    _ instructions: BindingExpression<F>...,
    yield value: @autoclosure @escaping () -> A) -> Kind<F, A> {
    MonadComprehension<F>.buildBlock(instructions, yield: value)
}

/// Monad comprehension.
///
/// Chains multiple binding expressions in imperative-style syntax by using the `flatMap` operation of the contextual `Monad`, and yields a final result.
///
/// - Parameters:
///   - instructions: A variable number of binding expressions.
///   - value: Value to be yield by the monad comprehension.
/// - Returns: An effect resulting from the chaining of all the effects included in this monad comprehension.
public func binding<F: Monad, A>(
    @BindingsBuilder _ instructions: () -> [BindingExpression<F>],
    yield value: @escaping () -> A) -> Kind<F, A> {
    MonadComprehension<F>.buildBlock(instructions(), yield: value)
}

@_functionBuilder
public struct BindingsBuilder {
    public static func buildBlock<F>(_ instructions: BindingExpression<F>...) -> [BindingExpression<F>] {
        instructions
    }
}
