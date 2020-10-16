import XCTest
import SwiftCheck
@testable import BowLaws
import Bow

extension LazyFunction1Partial: EquatableK where I == Int {
    public static func eq<A>(_ lhs: Kind<LazyFunction1Partial<I>, A>, _ rhs: Kind<LazyFunction1Partial<I>, A>) -> Bool where A : Equatable {
        LazyFunction1.fix(lhs).run(1)
            ==
        LazyFunction1.fix(rhs).run(1)
    }
}

extension LazyFunction1: Semigroup where I == O {
    public func combine(_ other: LazyFunction1) -> LazyFunction1 {
        andThen(other)
    }
}

class LazyFunction1Test: XCTestCase {
    func testFunctorLaws() {
        FunctorLaws<LazyFunction1Partial<Int>>.check()
    }

    func testEquivalenceToFunction1() {
        property("LazyFunction1 gives the same result than Function1") <~ forAll() { (i: Int, f: ArrowOf<Int, String>, g: ArrowOf<String, Int>) in
            (g.getArrow <<< f.getArrow)(i)
                ==
            LazyFunction1(f.getArrow).andThen(LazyFunction1(g.getArrow)).run(i)
        }
    }

    func testStackSafety() {
        let iterations = 200000
        let sum: LazyFunction1<Int, Int> = LazyFunction1({ $0 + 1 })
        let f = LazyFunction1.combineAll(sum, Array(repeating: sum, count: iterations - 1))

        XCTAssertEqual(f.run(0), iterations)
    }
}
