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
        let suhoor = app.descendants(matching: .any)["morningHero.quickWakeMode.suhoor"]
        let fajr = app.descendants(matching: .any)["morningHero.quickWakeMode.fajr"]
        let quiet = app.descendants(matching: .any)["morningHero.quickWakeMode.quiet"]

        XCTAssertTrue(selector.waitForExistence(timeout: 4))
        XCTAssertTrue(suhoor.exists)
        XCTAssertTrue(fajr.exists)
        XCTAssertTrue(quiet.exists)
        XCTAssertTrue(fajr.label.contains("selected"))

        suhoor.tap()

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: initialWakeLabel))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr begins")
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.suhoor") {
            $0.contains("selected")
        })
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow.marker"].exists)
        let primarySlotYBeforeQuiet = primaryWakeTime.frame.midY
        let windowSlotYBeforeQuiet = app.descendants(matching: .any)["morningHero.fajrWindow"].frame.midY
        let relationSlotYBeforeQuiet = relation.frame.midY
        let selectorSlotYBeforeQuiet = selector.frame.midY

        let quietAfterFast = app.descendants(matching: .any)["morningHero.quickWakeMode.quiet"]
        XCTAssertTrue(quietAfterFast.waitForExistence(timeout: 4))
        quietAfterFast.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.primaryWakeTime") {
            $0 == "Quiet mode"
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0 == "No alarm will ring for tomorrow"
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.quiet") {
            $0.contains("selected")
        })
        XCTAssertLessThan(abs(primaryWakeTime.frame.midY - primarySlotYBeforeQuiet), 10)
        XCTAssertLessThan(abs(app.descendants(matching: .any)["morningHero.fajrWindow"].frame.midY - windowSlotYBeforeQuiet), 10)
        XCTAssertLessThan(abs(relation.frame.midY - relationSlotYBeforeQuiet), 10)
        XCTAssertLessThan(abs(selector.frame.midY - selectorSlotYBeforeQuiet), 10)
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow.track"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["morningHero.fajrWindow.marker"].exists)

        let quietWakeLabel = primaryWakeTime.label
        let fajrAfterQuiet = app.descendants(matching: .any)["morningHero.quickWakeMode.fajr"]
        XCTAssertTrue(fajrAfterQuiet.waitForExistence(timeout: 4))
        fajrAfterQuiet.tap()

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: quietWakeLabel))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr ends")
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.fajr") {
            $0.contains("selected")
        })
        XCTAssertTrue(app.descendants(matching: .any)["morningHero.fajrWindow.marker"].waitForExistence(timeout: 4))

        let fajrWakeAfterQuiet = primaryWakeTime.label
        let suhoorAfterQuietFajr = app.descendants(matching: .any)["morningHero.quickWakeMode.suhoor"]
        XCTAssertTrue(suhoorAfterQuietFajr.waitForExistence(timeout: 4))
        suhoorAfterQuietFajr.tap()

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: fajrWakeAfterQuiet))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr begins")
        })
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.quickWakeMode.suhoor") {
            $0.contains("selected")
        })

        let quietAfterSuhoorAgain = app.descendants(matching: .any)["morningHero.quickWakeMode.quiet"]
        XCTAssertTrue(quietAfterSuhoorAgain.waitForExistence(timeout: 4))
        quietAfterSuhoorAgain.tap()
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.primaryWakeTime") {
            $0 == "Quiet mode"
        })

        let suhoorAfterSecondQuiet = app.descendants(matching: .any)["morningHero.quickWakeMode.suhoor"]
        XCTAssertTrue(suhoorAfterSecondQuiet.waitForExistence(timeout: 4))
        suhoorAfterSecondQuiet.tap()
        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: "Quiet mode"))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr begins")
        })

        let suhoorWakeAfterQuiet = primaryWakeTime.label
        let fajrAfterQuietSuhoor = app.descendants(matching: .any)["morningHero.quickWakeMode.fajr"]
        XCTAssertTrue(fajrAfterQuietSuhoor.waitForExistence(timeout: 4))
        fajrAfterQuietSuhoor.tap()

        XCTAssertTrue(waitForLabelChange(in: app, identifier: "morningHero.primaryWakeTime", from: suhoorWakeAfterQuiet))
        XCTAssertTrue(waitForElementLabel(in: app, identifier: "morningHero.relation") {
            $0.contains("before Fajr ends")
        })
    }

    func testNextTenMorningsForecastStartsCollapsedAndExpands() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-morning-hero-fajr-adjuster",
            "--ui-testing-fixed-now=2026-04-26T12:00:00Z",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        let header = app.descendants(matching: .any)["nextTenMornings.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 12))
        if !header.isHittable {
            app.swipeUp()
            XCTAssertTrue(header.waitForExistence(timeout: 4))
        }
        XCTAssertEqual(header.value as? String, "Collapsed")

        let firstRow = app.descendants(matching: .any)
            .matching(identifier: "nextTenMornings.row")
            .firstMatch
        XCTAssertFalse(firstRow.exists)

        header.tap()
        XCTAssertTrue(waitForElementValue(in: app, identifier: "nextTenMornings.header") {
            $0 == "Expanded"
        })
        XCTAssertTrue(firstRow.waitForExistence(timeout: 4))

        firstRow.tap()
        XCTAssertTrue(app.descendants(matching: .any)["alarmDetail.dateLine"].waitForExistence(timeout: 8))
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

    private func waitForElementValue(
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
            if element.exists,
               let value = element.value as? String,
               predicate(value) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline

        XCTFail("Expected \(identifier) value to match predicate", file: file, line: line)
        return false
    }
}
