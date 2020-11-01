import XCTest
@testable import Stack

final class StackTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Stack().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
