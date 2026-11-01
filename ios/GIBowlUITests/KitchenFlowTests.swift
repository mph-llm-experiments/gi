import XCTest

final class KitchenFlowTests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["GI Bowl"].waitForExistence(timeout: 5))
    }
}
