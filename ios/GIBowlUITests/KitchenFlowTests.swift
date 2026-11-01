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

    private func open(_ app: XCUIApplication, _ query: String, _ name: String) {
        search(app, query)
        app.staticTexts[name].firstMatch.tap()
    }

    private func bowlState(_ app: XCUIApplication) -> String {
        let el = app.staticTexts["bowl.state"]
        XCTAssertTrue(el.waitForExistence(timeout: 5))
        return el.label
    }

    func testCanIAddFruitToCottageCheese() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()
        open(app, "cottage", "Cottage cheese")
        app.buttons["portion.½ cup"].tap()
        let meal = app.textFields["targets.meal"]
        XCTAssertTrue(meal.waitForExistence(timeout: 5))
        meal.tap(); meal.typeText("45")
        app.textFields["targets.snack"].tap(); app.textFields["targets.snack"].typeText("15")
        app.buttons["targets.save"].tap()
        XCTAssertEqual(bowlState(app), "Room to spare")
        XCTAssertEqual(app.staticTexts["bowl.hint"].label, "Room for about 10g more")
        // ½ cup blueberries (8.9g) + cottage cheese (5.4g) = 14.3g of 15 → Close
        open(app, "blueberries", "Blueberries")
        app.buttons["portion.½ cup"].tap()
        XCTAssertEqual(bowlState(app), "Close to your number")
        snapshot("bowl-close")
    }

    func testOverThenRemoveThenStartOver() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        open(app, "cottage", "Cottage cheese")
        app.buttons["portion.½ cup"].tap()
        open(app, "banana", "Banana, raw")
        app.buttons["portion.1 large"].tap()
        XCTAssertEqual(bowlState(app), "Over your number")
        XCTAssertEqual(app.staticTexts["bowl.hint"].label, "Roughly 20g past it")
        snapshot("bowl-over")
        let banana = app.staticTexts["Banana, raw · 1 large"]
        banana.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertEqual(bowlState(app), "Room to spare")
        app.buttons["Start over"].tap()
        XCTAssertTrue(app.staticTexts["Start a bowl"].waitForExistence(timeout: 5))
    }

    func testMealModeUsesMealNumber() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        open(app, "banana", "Banana, raw")
        app.buttons["portion.1 large"].tap()
        XCTAssertEqual(bowlState(app), "Over your number")
        app.buttons["Meal"].tap()
        XCTAssertEqual(bowlState(app), "Room to spare")
    }

    private func fillOwnFood(_ app: XCUIApplication, name: String?, portion: String, carbs: String) {
        let nameField = app.textFields["own.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        if let name { nameField.tap(); nameField.typeText(name) }
        app.textFields["own.portion"].tap(); app.textFields["own.portion"].typeText(portion)
        app.textFields["own.carbs"].tap(); app.textFields["own.carbs"].typeText(carbs)
        app.buttons["own.save"].tap()
    }

    func testAddOwnFood() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        search(app, "fage")
        app.buttons["own.add"].tap()
        fillOwnFood(app, name: nil, portion: "1 cup", carbs: "9")   // name prefilled from the search
        XCTAssertTrue(app.staticTexts["GI"].waitForExistence(timeout: 5))
        app.buttons["portion.1 cup"].tap()
        XCTAssertEqual(bowlState(app), "Room to spare")
        XCTAssertEqual(app.staticTexts["bowl.hint"].label, "Room for about 5g more")
        search(app, "fage")
        XCTAssertTrue(app.staticTexts["Yours"].waitForExistence(timeout: 5))
    }

    func testAddCarbsForAStudyFoodWithout() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        open(app, "jasmine rice", "Jasmine rice, cooked in rice cooker (SunRice; Ricegrowers Ltd., NSW, Australia)")
        app.buttons["own.addCarbs"].tap()
        fillOwnFood(app, name: nil, portion: "1 cup", carbs: "45")
        XCTAssertTrue(app.buttons["portion.1 cup"].waitForExistence(timeout: 5))
    }

    func testEditAndDeleteOwnFoodKeepsBowl() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        search(app, "fage")
        app.buttons["own.add"].tap()
        fillOwnFood(app, name: nil, portion: "1 cup", carbs: "9")
        app.buttons["portion.1 cup"].tap()
        open(app, "fage", "fage")
        app.buttons["own.menu"].tap()
        app.buttons["Delete"].tap()
        app.buttons["Delete food"].tap()
        XCTAssertTrue(app.staticTexts["fage · 1 cup"].waitForExistence(timeout: 5))
    }
}
