import XCTest

final class KitchenFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func search(_ app: XCUIApplication, _ text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != "Search foods" {
            field.buttons["Clear text"].tap()
        }
        field.typeText(text)
    }

    /// Saves a screenshot where the developer can look at it (path from SCREENSHOT_DIR).
    private func snapshot(_ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }

    func testSearchToleratesTyposAndShowsPortions() {
        let app = XCUIApplication()
        app.launch()
        search(app, "cotage")
        app.staticTexts["Cottage cheese"].firstMatch.tap()
        XCTAssertTrue(app.buttons["portion.½ cup"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["portion.1 cup"].exists)
        snapshot("detail-cottage")
    }

    func testLongNamesAtLargestTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        search(app, "sustagen")
        snapshot("xxl-search")
        app.cells.firstMatch.tap()
        snapshot("xxl-detail")
    }
}
