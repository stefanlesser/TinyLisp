import XCTest
@testable import TinyLisp

final class TinyLispTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TinyLisp().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
