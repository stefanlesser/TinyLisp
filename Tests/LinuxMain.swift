import XCTest

import TinyLispTests

var tests = [XCTestCaseEntry]()
tests += TinyLispTests.allTests()
XCTMain(tests)
