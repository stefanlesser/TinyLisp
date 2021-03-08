import XCTest
@testable import TinyLisp

class TinyLispTests: XCTestCase {
    private var lisp: LispMinimal!

    override func setUp() {
        super.setUp()
        lisp = LispMinimal()
    }

    func testAtomValue() {
        XCTAssertEqual("abc", try lisp.eval("abc"))
    }

    func testLabelAtom() throws {
        _ = try lisp.eval(["label", "a", "42"])
        XCTAssertEqual("42", try lisp.eval("a"))
    }

    func testQuoteList() {
        XCTAssertEqual(["1", "2"], try lisp.eval(["quote", ["1", "2"]]))
    }

    func testCar() {
        XCTAssertEqual("1", try lisp.eval(["car", ["quote", ["1", "2"]]]))
    }

    func testCdr() {
        XCTAssertEqual(["2"], try lisp.eval(["cdr", ["quote", ["1", "2"]]]))
    }

    func testCons() {
        XCTAssertEqual(["1", "2", "3"], try lisp.eval(["cons", "1", ["quote", ["2", "3"]]]))
    }

    func testLambda() throws {
        _ = try lisp.eval(["label", "second", ["quote", ["lambda", ["x"], ["car", ["cdr", "x"]]]]])
        XCTAssertEqual("2", try lisp.eval(["second", ["quote", ["1", "2", "3"]]]))
    }
}
