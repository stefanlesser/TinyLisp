import XCTest
@testable import TinyLisp

class TinyLispBooleanTests: TinyLispTests {
    private var lisp: LispBoolean!

    override func setUp() {
        super.setUp()
        lisp = LispBoolean()
    }

    func testIsAtom() {
        XCTAssertEqual(false, try lisp.eval(["atom", ["quote", ["1", "2"]]]))
        XCTAssertEqual(true, try lisp.eval(["atom", ["quote", "2"]]))
    }

    func testEqAtom() throws {
        _ = try lisp.eval(["label", "a", "42"])
        XCTAssertEqual(true, try lisp.eval(["eq", "42", "a"]))
        XCTAssertEqual(false, try lisp.eval(["eq", "43", "a"]))
    }

    func testIf() {
        XCTAssertEqual("42", try lisp.eval(["if", ["eq", "1", "1"], "42", "43"]))
        XCTAssertEqual("43", try lisp.eval(["if", ["eq", "1", "2"], "42", "43"]))
    }
}
