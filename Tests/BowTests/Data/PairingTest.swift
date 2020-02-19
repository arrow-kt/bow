import XCTest
import Bow

class PairingTest: XCTestCase {
    func testPairingStateStore() {
        let w = Store<Int, Int>(0, id)
        let s = State<Int, Int>.var()
        
        let actions: State<Int, Void> = binding(
            |<-.set(5),
            |<-.modify { x in x + 5 },
            s <- .get(),
            |<-.set(s.get * 3 + 1),
            yield: ())^
        
        let w2 = Pairing.pairStateStore().select(actions, w.duplicate())
        
        XCTAssertEqual(w2.extract(), 31)
    }
    
    func testPairingWriterTraced() {
        let w = Traced<Int, String> { x in Array(repeating: "*", count: x).joined() }
        
        let m = Writer<Int, Int>.var()
        let a = Writer<Int, Void>.var()
        
        let actions: Writer<Int, Void> = binding(
            (m, a) <- Writer.tell(3).censor { x in 2 * x }.listens(id),
            |<-.tell(m.get + 1),
            yield: ())^
        
        let w2 = Pairing.pairWriterTraced().select(actions, w.duplicate())
        
        XCTAssertEqual(w2.extract(), "*************")
    }
    
    func testPairingReaderEnv() {
        let w = Env<Int, Double>(10, .pi)
        
        let e1 = Reader<Int, Int>.var()
        let e2 = Reader<Int, Int>.var()
        var res = 0
        
        let actions: Reader<Int, Int> = binding(
            e1 <- Reader.ask().local { x in 2 * x },
            e2 <- Reader.pure(e1.get * 3),
            |<-Reader<Int, Void> { _ in
                res = e2.get
                return Id(())
            },
            yield: e2.get)^
        
        let _ = Pairing.pairReaderEnv().select(actions, w.duplicate())
        
        XCTAssertEqual(res, 60)
    }
    
    func testPairingActionMoore() {
        func render(_ n: Int) -> String {
            (n % 2 == 0) ?
                "\(n) is even" :
                "\(n) is odd"
        }
        
        func update(_ state: Int, _ action: Input) -> Int {
            switch action {
            case .increment: return state + 1
            case .decrement: return state - 1
            }
        }
        
        enum Input {
            case increment
            case decrement
        }
        
        let w = Moore<Input, String>.from(initialState: 0, render: render, update: update)
        
        let actions: Action<Input, Void> = binding(
            |<-Action.from(.increment),
            |<-Action.from(.increment),
            |<-Action.from(.decrement),
            |<-Action.from(.increment),
            |<-Action.from(.increment),
            yield: ())^
        
        let w2 = Pairing.pairActionMoore().select(actions, w.duplicate())^
        
        XCTAssertEqual(w2.view, "3 is odd")
    }
}
