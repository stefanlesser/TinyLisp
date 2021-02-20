import XCTest
@testable import TinyLisp

final class TinyLisp2Tests: XCTestCase {
    var lisp: Lisp2 = Lisp2()

    let fib: Expr = ["label", "fib",
                      ["quote", ["lambda", ["n"],
                        ["if", ["<", "n", 2],
                        "n",
                        ["+", ["fib", ["-", "n", 1]], ["fib", ["-", "n", 2]]]]]]]

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

    func testFib() throws {
        _ = try lisp.eval(fib)
        XCTAssertEqual(1, try lisp.eval(["fib", 1]))
        XCTAssertEqual(1, try lisp.eval(["fib", 2]))
        XCTAssertEqual(2, try lisp.eval(["fib", 3]))
        XCTAssertEqual(3, try lisp.eval(["fib", 4]))
        XCTAssertEqual(5, try lisp.eval(["fib", 5]))
        XCTAssertEqual(8, try lisp.eval(["fib", 6]))
        XCTAssertEqual(13, try lisp.eval(["fib", 7]))
        XCTAssertEqual(21, try lisp.eval(["fib", 8]))
        XCTAssertEqual(34, try lisp.eval(["fib", 9]))
        XCTAssertEqual(55, try lisp.eval(["fib", 10]))
    }

    func testFibPerformance() throws {
        _ = try lisp.eval(fib)
        measure {
            XCTAssertEqual(6765, try? lisp.eval(["fib", 20])) // average: 0.17 sec
        }
    }
}
