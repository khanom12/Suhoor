import Testing
@testable import Subh

@Suite
struct OnboardingPresentationTests {
    @Test
    func onboardingPathResolvesRamadanWhenHijriMonthIsRamadan() {
        #expect(OnboardingPath.resolve(currentHijriMonth: .ramadan) == .ramadan)
    }

    @Test
    func onboardingPathDefaultsToFajrOutsideRamadanOrWhenUnavailable() {
        #expect(OnboardingPath.resolve(currentHijriMonth: .shawwal) == .fajr)
        #expect(OnboardingPath.resolve(currentHijriMonth: nil) == .fajr)
    }

    @Test
    func ramadanAndFajrUseDifferentStepShapes() {
        #expect(OnboardingPath.ramadan.flowSteps == [.valuePreview, .location, .relationship, .futureVisualization, .permissions, .success])
        #expect(OnboardingPath.fajr.flowSteps == [.valuePreview, .location, .relationship, .supportBehavior, .permissions, .success])
    }

    @Test
    func fajrPathKeepsEvergreenSupportAndRamadanKeepsSeasonalIdentity() {
        #expect(OnboardingPath.fajr.previewWakeLabel == "Next wake")
        #expect(OnboardingPath.ramadan.previewWakeLabel == "Subh wake")
        #expect(OnboardingPath.fajr.showsCalculationMethodSummary)
        #expect(OnboardingPath.ramadan.showsCalculationMethodSummary == false)
        #expect(OnboardingPath.fajr.successSecondaryActionTitle == "Add fasting support in Plans")
        #expect(OnboardingPath.ramadan.successSecondaryActionTitle == nil)
    }
}
