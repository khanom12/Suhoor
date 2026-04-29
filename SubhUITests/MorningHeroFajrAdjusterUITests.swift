import XCTest

final class MorningHeroFajrAdjusterUITests: XCTestCase {
    func testMorningHeroFajrAdjusterRendersAndDrags() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-morning-hero-fajr-adjuster",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        let location = app.descendants(matching: .any)["morningHero.location"]
        XCTAssertTrue(location.waitForExistence(timeout: 12))
        XCTAssertEqual(location.label, "Toronto")

        let relativeDay = app.descendants(matching: .any)["morningHero.relativeDay"]
        XCTAssertTrue(relativeDay.waitForExistence(timeout: 4))

        let primaryWakeTime = app.descendants(matching: .any)["morningHero.primaryWakeTime"]
        XCTAssertTrue(primaryWakeTime.waitForExistence(timeout: 12))

        let initialWakeLabel = primaryWakeTime.label
        XCTAssertFalse(initialWakeLabel.isEmpty)

        let relation = app.descendants(matching: .any)["morningHero.relation"]
        XCTAssertTrue(relation.waitForExistence(timeout: 4))
        let initialRelationLabel = relation.label
        XCTAssertTrue(initialRelationLabel.hasPrefix("Wake up "))
        XCTAssertTrue(initialRelationLabel.contains(" min before Fajr ends"))

        let fajrWindow = app.descendants(matching: .any)["morningHero.fajrWindow"]
        let beginTime = app.descendants(matching: .any)["morningHero.fajrWindow.beginTime"]
        let track = app.descendants(matching: .any)["morningHero.fajrWindow.track"]
        let marker = app.descendants(matching: .any)["morningHero.fajrWindow.marker"]
        let endTime = app.descendants(matching: .any)["morningHero.fajrWindow.endTime"]

        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertTrue(beginTime.exists)
        XCTAssertTrue(track.exists)
        XCTAssertTrue(marker.exists)
        XCTAssertTrue(endTime.exists)
        XCTAssertLessThan(location.frame.maxY, relativeDay.frame.minY)
        XCTAssertLessThan(fajrWindow.frame.maxY, relation.frame.minY)

        let markerStart = marker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let trackEnd = track.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5))
        markerStart.press(forDuration: 0.15, thenDragTo: trackEnd)

        let wakeChanged = NSPredicate(format: "label != %@", initialWakeLabel)
        expectation(for: wakeChanged, evaluatedWith: primaryWakeTime)
        waitForExpectations(timeout: 6)

        XCTAssertNotEqual(relation.label, initialRelationLabel)
        XCTAssertTrue(relation.label.hasPrefix("Wake up "))
        XCTAssertTrue(relation.label.contains(" min before Fajr ends"))
        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertTrue(marker.exists)

        let wakeAfterEndDrag = primaryWakeTime.label
        let markerAfterEndDrag = app.descendants(matching: .any)["morningHero.fajrWindow.marker"]
        let trackStart = track.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        markerAfterEndDrag.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.15, thenDragTo: trackStart)

        let wakeChangedAtBegin = NSPredicate(format: "label != %@", wakeAfterEndDrag)
        expectation(for: wakeChangedAtBegin, evaluatedWith: primaryWakeTime)
        waitForExpectations(timeout: 6)

        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertTrue(beginTime.exists)
        XCTAssertTrue(track.exists)
        XCTAssertTrue(markerAfterEndDrag.exists)
        XCTAssertTrue(endTime.exists)
    }
}
