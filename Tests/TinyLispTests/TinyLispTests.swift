import XCTest
@testable import TinyLisp

final class TinyLispTests: XCTestCase {
    var lisp: Lisp = Lisp()

    func testAtomValue() {
        XCTAssertEqual("abc", try lisp.eval("abc"))
    }

    func testLabelAtom() throws {
        _ = try lisp.eval(["label", "a", "42"])
        XCTAssertEqual("42", try lisp.eval("a"))
    }

    func testEqAtom() throws {
        _ = try lisp.eval(["label", "a", "42"])
        XCTAssertEqual("T", try lisp.eval(["eq", "42", "a"]))
        XCTAssertEqual([], try lisp.eval(["eq", "43", "a"]))
    }

    func testQuoteList() {
        XCTAssertEqual(["1", "2"], try lisp.eval(["quote", ["1", "2"]]))
    }

    func testIf() {
        XCTAssertEqual("42", try lisp.eval(["if", ["eq", "1", "1"], "42", "43"]))
        XCTAssertEqual("43", try lisp.eval(["if", ["eq", "1", "2"], "42", "43"]))
    }

    func testIsAtom() {
        XCTAssertEqual([], try lisp.eval(["atom", ["quote", ["1", "2"]]]))
        XCTAssertEqual("T", try lisp.eval(["atom", ["quote", "2"]]))
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
