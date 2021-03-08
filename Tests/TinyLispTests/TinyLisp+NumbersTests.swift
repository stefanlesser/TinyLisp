import XCTest
@testable import TinyLisp

final class TinyLispNumbersTests: TinyLispBooleanTests {
    private var lisp: LispNumbers!

    override func setUp() {
        super.setUp()
        lisp = LispNumbers()
    }

    private let fib: Expr = ["label", "fib",
                      ["quote", ["lambda", ["n"],
                        ["if", ["<", "n", 2],
                        "n",
                        ["+", ["fib", ["-", "n", 1]], ["fib", ["-", "n", 2]]]]]]]

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
