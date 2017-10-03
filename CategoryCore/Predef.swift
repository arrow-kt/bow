//
//  Predef.swift
//  CategoryCore
//
//  Created by Tomás Ruiz López on 28/9/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public func id<A>(_ a : A) -> A {
    return a
}

func constF<A>(_ a : A) -> () -> A {
    return { a }
}

func constF<A, B>(_ a : A) -> (B) -> A {
    return { _ in a }
}

func constF<A, B, C>(_ a : A) -> (B, C) -> A {
    return { _, _ in a }
}

func constF<A, B, C, D>(_ a : A) -> (B, C, D) -> A {
    return { _, _, _ in a }
}

func constF<A, B, C, D, E>(_ a : A) -> (B, C, D, E) -> A {
    return { _, _, _, _ in a }
}

public func compose<A, B>(_ f : @escaping () -> A, _ g : @escaping (A) -> B) -> () -> B {
    return { g(f()) }
}

public func compose<A, B, C>(_ f : @escaping (A) -> B, _ g : @escaping (B) -> C) -> (A) -> C {
    return { x in g(f(x)) }
}

infix operator >> : AdditionPrecedence
infix operator << : AdditionPrecedence

public func >><A, B>(_ f : @escaping () -> A, _ g : @escaping (A) -> B) -> () -> B {
    return compose(f, g)
}

public func >><A, B, C>(_ f : @escaping (A) -> B, _ g : @escaping (B) -> C) -> (A) -> C {
    return compose(f, g)
}

public func <<<A, B>(_ g : @escaping (A) -> B, _ f : @escaping () -> A) -> () -> B {
    return f >> g
}

public func <<<A, B, C>(_ g : @escaping (B) -> C, _ f : @escaping (A) -> B) -> (A) -> C {
    return f >> g
}

