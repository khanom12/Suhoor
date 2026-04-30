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

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: initialWakeLabel))

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

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: wakeAfterEndDrag))

        XCTAssertEqual(relation.label, "Wake up as Fajr begins")
        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertTrue(beginTime.exists)
        XCTAssertTrue(track.exists)
        XCTAssertTrue(markerAfterEndDrag.exists)
        XCTAssertTrue(endTime.exists)
    }

    func testMorningHeroEarlyWorshipAdjusterRendersAndDrags() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-morning-hero-early-worship-adjuster",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        let primaryWakeTime = app.descendants(matching: .any)["morningHero.primaryWakeTime"]
        XCTAssertTrue(primaryWakeTime.waitForExistence(timeout: 12))
        let initialWakeLabel = primaryWakeTime.label

        let relation = app.descendants(matching: .any)["morningHero.relation"]
        XCTAssertTrue(relation.waitForExistence(timeout: 4))
        XCTAssertTrue(relation.label.hasPrefix("Wake up "))
        XCTAssertTrue(relation.label.contains(" min before Fajr begins"))

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

        let markerStart = marker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let trackLeft = track.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        markerStart.press(forDuration: 0.15, thenDragTo: trackLeft)

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: initialWakeLabel))

        XCTAssertEqual(relation.label, "Wake up for the last third of the night")
        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertTrue(marker.exists)

        let markerAfterLeftDrag = app.descendants(matching: .any)["morningHero.fajrWindow.marker"]
        let trackRight = track.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.5))
        markerAfterLeftDrag.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.15, thenDragTo: trackRight)

        XCTAssertTrue(fajrWindow.waitForExistence(timeout: 4))
        XCTAssertEqual(relation.label, "Wake up as Fajr begins")
    }

    func testMorningHeroQuickWakeModeSelectorUpdatesResolvedState() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-morning-hero-fajr-adjuster",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        let primaryWakeTime = app.descendants(matching: .any)["morningHero.primaryWakeTime"]
        XCTAssertTrue(primaryWakeTime.waitForExistence(timeout: 12))
        let initialWakeLabel = primaryWakeTime.label

        let relation = app.descendants(matching: .any)["morningHero.relation"]
        XCTAssertTrue(relation.waitForExistence(timeout: 4))
        XCTAssertTrue(relation.label.contains("before Fajr ends"))

        let selector = app.descendants(matching: .any)["morningHero.quickWakeMode"]
        let fast = app.descendants(matching: .any)["morningHero.quickWakeMode.fast"]
        let fajr = app.descendants(matching: .any)["morningHero.quickWakeMode.fajr"]
        let quiet = app.descendants(matching: .any)["morningHero.quickWakeMode.quiet"]

        XCTAssertTrue(selector.waitForExistence(timeout: 4))
        XCTAssertTrue(fast.exists)
        XCTAssertTrue(fajr.exists)
        XCTAssertTrue(quiet.exists)
        XCTAssertTrue(fajr.label.contains("selected"))

        fast.tap()

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: initialWakeLabel))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr begins")
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.fast") {
            $0.contains("selected")
        })
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow.marker"].exists)
        let primarySlotYBeforeQuiet = primaryWakeTime.frame.midY

        let quietAfterFast = app.descendants(matching: .any)["morningHero.quickWakeMode.quiet"]
        XCTAssertTrue(quietAfterFast.waitForExistence(timeout: 4))
        quietAfterFast.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.primaryWakeTime") {
            $0 == "Quiet mode on"
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0 == "No alarm will ring for tomorrow"
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.quiet") {
            $0.contains("selected")
        })
        XCTAssertLessThan(abs(primaryWakeTime.frame.midY - primarySlotYBeforeQuiet), 10)
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow.track"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["morningHero.fajrWindow.marker"].exists)
    }

    private func waitForLabelChange(
        in app: XCUIApplication,
        identifier: String,
        from originalLabel: String,
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let element = app.descendants(matching: .any)[identifier]
            if element.exists, element.label != originalLabel {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        XCTFail("Expected \(identifier) label to change from \(originalLabel)", file: file, line: line)
        return false
    }

    private func waitForElementLabel(
        in app: XCUIApplication,
        identifier: String,
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line,
        matches predicate: (String) -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let element = app.descendants(matching: .any)[identifier]
            if element.exists, predicate(element.label) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        XCTFail("Expected \(identifier) label to match predicate", file: file, line: line)
        return false
    }
}
