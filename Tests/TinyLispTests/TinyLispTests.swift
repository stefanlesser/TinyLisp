import XCTest
@testable import TinyLisp

final class TinyLispTests: XCTestCase {
    var lisp: Lisp = Lisp()

    func testAtomValue() {
        XCTAssertEqual("abc", lisp.eval("abc"))
    }

    func testLabelAtom() {
        _ = lisp.eval(["label", "a", "42"])
        XCTAssertEqual("42", lisp.eval("a"))
    }

    func testEqAtom() {
        _ = lisp.eval(["label", "a", "42"])
        XCTAssertEqual("T", lisp.eval(["eq", "42", "a"]))
        XCTAssertEqual([], lisp.eval(["eq", "43", "a"]))
    }

    func testQuoteList() {
        XCTAssertEqual(["1", "2"], lisp.eval(["quote", ["1", "2"]]))
    }

    func testIf() {
        XCTAssertEqual("42", lisp.eval(["if", ["eq", "1", "1"], "42", "43"]))
        XCTAssertEqual("43", lisp.eval(["if", ["eq", "1", "2"], "42", "43"]))
    }

    func testIsAtom() {
        XCTAssertEqual([], lisp.eval(["atom", ["quote", ["1", "2"]]]))
        XCTAssertEqual("T", lisp.eval(["atom", ["quote", "2"]]))
    }

    func testCar() {
        XCTAssertEqual("1", lisp.eval(["car", ["quote", ["1", "2"]]]))
    }

    func testCdr() {
        XCTAssertEqual(["2"], lisp.eval(["cdr", ["quote", ["1", "2"]]]))
    }

    func testCons() {
        XCTAssertEqual(["1", "2", "3"], lisp.eval(["cons", "1", ["quote", ["2", "3"]]]))
    }

    func testLambda() {
        _ = lisp.eval(["label", "second", ["quote", ["lambda", ["x"], ["car", ["cdr", "x"]]]]])
        XCTAssertEqual("2", lisp.eval(["second", ["quote", ["1", "2", "3"]]]))
    }
}
