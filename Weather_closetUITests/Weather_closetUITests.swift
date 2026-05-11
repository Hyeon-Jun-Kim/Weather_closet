import XCTest

final class Weather_closetUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTabBarExists() {
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
