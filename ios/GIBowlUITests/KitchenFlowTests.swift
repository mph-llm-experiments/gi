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
        app.launchArguments = ["-resetData", "-seedTargets", "45,15", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        search(app, "vitasoy maltodextrin")
        // The 158-character name is over XCUITest's 128-character identifier limit, so match by prefix
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "containing maltodextrin (So Natural Foods")).firstMatch
        // "Add your own food" rows sit above results, so at this size the row starts below the fold
        for _ in 0..<6 where !(row.exists && row.isHittable) { app.swipeUp() }
        snapshot("xxl-search")
        XCTAssertTrue(row.exists)
        // At this size the row is taller than the space above the keyboard; tap its top
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.05)).tap()
        XCTAssertTrue(app.staticTexts["GI"].waitForExistence(timeout: 5))
        snapshot("xxl-detail")
        // The title fills the screen at this size; scroll to the portions
        let button = app.buttons["portion.Small glass"]
        for _ in 0..<6 where !(button.exists && button.isHittable) { app.swipeUp() }
        snapshot("xxl-portions")
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(app.staticTexts["bowl.state"].waitForExistence(timeout: 5))
        snapshot("xxl-bowl")
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
        search(app, "blueberries")
        XCTAssertTrue(app.staticTexts["bowl.state"].exists)
        XCTAssertFalse(app.staticTexts["Cottage cheese"].exists, "bowl collapses to its state while searching")
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
        let banana = app.staticTexts["Banana, raw"]
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
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "fage")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["bowl.hint"].label, "Room for about 5g more")
    }

    func testNumbersAreOptional() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()
        open(app, "cottage", "Cottage cheese")
        app.buttons["portion.½ cup"].tap()
        XCTAssertTrue(app.textFields["targets.meal"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertEqual(bowlState(app), "About 5g so far")
        open(app, "banana", "Banana, raw")
        app.buttons["portion.1 small"].tap()
        XCTAssertFalse(app.textFields["targets.meal"].waitForExistence(timeout: 2), "asks only once")
        XCTAssertEqual(bowlState(app), "About 25g so far")
    }

    func testPickMealBeforeTheFirstItem() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15"]
        app.launch()
        let meal = app.buttons["Meal"]
        XCTAssertTrue(meal.waitForExistence(timeout: 5))
        meal.tap()
        open(app, "banana", "Banana, raw")
        XCTAssertTrue(app.staticTexts["Against your meal number: 45g"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["portion.1 large"].value as? String, "Room to spare")
    }

    private func readSampleLabel(_ app: XCUIApplication) -> String {
        let sample = app.buttons["label.sample"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        sample.tap()
        let banner = app.staticTexts["label.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 20))
        return banner.label
    }

    func testAddFromUSLabel() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedTargets", "45,15", "-labelFixture", "us"]
        app.launch()
        search(app, "granola")
        app.buttons["own.add"].tap()
        XCTAssertEqual(readSampleLabel(app), "Read from the label. Check the numbers before saving.")
        XCTAssertEqual(app.textFields["own.carbs"].value as? String, "33")
        XCTAssertEqual(app.textFields["own.portion"].value as? String, "2/3 cup (55g)")
        app.buttons["own.save"].tap()
        XCTAssertTrue(app.buttons["portion.2/3 cup (55g)"].waitForExistence(timeout: 5))
    }

    func testBlankPhotoSaysSo() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-labelFixture", "blank"]
        app.launch()
        search(app, "mystery bar")
        app.buttons["own.add"].tap()
        XCTAssertEqual(readSampleLabel(app), "Couldn't read the label. Fill in what you can.")
        let carbs = app.textFields["own.carbs"].value as? String ?? ""
        XCTAssertTrue(carbs.isEmpty || carbs == "0", "carbs stay empty, got \(carbs)")
    }
    func testTipJarShowsPricesQuietly() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()
        XCTAssertFalse(app.staticTexts["Tip jar"].exists, "tips appear nowhere on the main screen")
        app.buttons["Settings"].tap()
        let small = app.buttons["tip.small"]
        for _ in 0..<4 where !small.exists { app.swipeUp() }
        XCTAssertTrue(small.waitForExistence(timeout: 10))
        XCTAssertEqual(small.label, "$1.99")
        small.tap()
        // StoreKit's local purchase sheet runs in another process
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for confirm in [app.buttons["Purchase"], springboard.buttons["Purchase"], app.buttons["Subscribe"], springboard.buttons["OK"], app.buttons["OK"]] where confirm.waitForExistence(timeout: 3) {
            confirm.tap()
            break
        }
        let thanks = app.staticTexts["tip.thanks"]
        if !thanks.waitForExistence(timeout: 15) {
            for _ in 0..<3 where !thanks.exists { app.swipeUp() }
        }
        XCTAssertTrue(thanks.exists)
    }
}
