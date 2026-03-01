import SwiftUI

struct FastTagAbout: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let aboutText: String
    let bullets: [String]
    let showsScheduleNote: Bool

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        aboutText: String,
        bullets: [String] = [],
        showsScheduleNote: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.aboutText = aboutText
        self.bullets = bullets
        self.showsScheduleNote = showsScheduleNote
    }

    static let rulesetAbout = FastTagAbout(
        id: "ruleset",
        title: "About ruleset",
        aboutText: "Scholars differ on whether some intentions can be combined. Choose the mode you follow. This only affects tagging and guidance, not when alarms fire.",
        showsScheduleNote: true
    )
}

extension FastPrimaryIntent {
    var about: FastTagAbout {
        switch self {
        case .ramadanObligatory:
            return FastTagAbout(
                id: "ramadan",
                title: "Ramadan",
                subtitle: "Obligatory fast during the month of Ramadan.",
                aboutText: "Fasting in Ramadan is obligatory for eligible Muslims. If this date falls in Ramadan, it takes precedence over voluntary fasting patterns."
            )
        case .qadaMakeup:
            return FastTagAbout(
                id: "qada",
                title: "Make-up (Qadāʾ)",
                subtitle: "Making up a missed Ramadan fast.",
                aboutText: "Use this for a fast that replaces a missed day of Ramadan. Some people avoid combining make-up fasts with voluntary fast intentions; this app can enforce that based on your ruleset."
            )
        case .kaffarahExpiation:
            return FastTagAbout(
                id: "kaffarah",
                title: "Expiation (Kaffārah)",
                subtitle: "Fasting required as expiation.",
                aboutText: "Use this when fasting is required as expiation. The exact requirement depends on the situation and personal guidance."
            )
        case .vowNadhr:
            return FastTagAbout(
                id: "vow",
                title: "Vow (Nadhr)",
                subtitle: "Fasting due to a personal vow.",
                aboutText: "Use this when you’re fasting because of a vow you made. Vow fasts are treated as a commitment and may follow specific personal conditions."
            )
        case .voluntarySunnah:
            return FastTagAbout(
                id: "voluntary",
                title: "Voluntary (Sunnah)",
                subtitle: "Optional fast for extra reward.",
                aboutText: "Use this for voluntary fasting. You can also add ‘This day also matches…’ tags when a voluntary fast coincides with specific recommended days."
            )
        case .other:
            return FastTagAbout(
                id: "other",
                title: "Other",
                subtitle: "A personal fast not listed above.",
                aboutText: "Use this for a fast that doesn’t fit the categories above."
            )
        }
    }
}

extension FastSecondaryVirtueTag {
    var about: FastTagAbout {
        switch self {
        case .shawwalSix:
            return FastTagAbout(
                id: "shawwal-six",
                title: "Six of Shawwāl",
                subtitle: "One of the six recommended days after Ramadan.",
                aboutText: "These are six voluntary fasts in Shawwāl (the month after Ramadan). People can fast any six days in the month."
            )
        case .arafah:
            return FastTagAbout(
                id: "arafah",
                title: "Day of ʿArafah",
                subtitle: "9th of Dhul Hijjah.",
                aboutText: "A voluntary fast on the 9th of Dhul Hijjah (for those not performing Hajj)."
            )
        case .ashura:
            return FastTagAbout(
                id: "ashura",
                title: "ʿĀshūrāʾ",
                subtitle: "9th or 10th of Muharram.",
                aboutText: "A voluntary fast associated with the 10th of Muharram, often paired with the 9th (or the 11th) to be distinct."
            )
        case .whiteDays:
            return FastTagAbout(
                id: "white-days",
                title: "White Days (13–15)",
                subtitle: "The 13th, 14th, and 15th of each Hijri month.",
                aboutText: "Called the ‘White Days’ because the moon is full and the nights are bright. These are recurring voluntary fast days each Hijri month."
            )
        case .mondayThursday:
            return FastTagAbout(
                id: "monday-thursday",
                title: "Mondays & Thursdays",
                subtitle: "Weekly voluntary fasts.",
                aboutText: "A common voluntary fasting pattern: Mondays and Thursdays each week."
            )
        case .dhulHijjahFirstNine:
            return FastTagAbout(
                id: "dhul-hijjah-first-nine",
                title: "First 9 Days of Dhul Hijjah",
                subtitle: "The first nine days of Dhul Hijjah.",
                aboutText: "Some people choose to fast during the first nine days of Dhul Hijjah, with the 9th (ʿArafah) as the peak."
            )
        }
    }
}

extension FastWarning {
    var about: FastTagAbout {
        switch self {
        case .eidAlFitr:
            return FastTagAbout(
                id: "warning-eid-al-fitr",
                title: "Eid al-Fitr",
                aboutText: "Fasting on Eid al-Fitr is generally not practiced. This day marks the end of Ramadan.",
                showsScheduleNote: false
            )
        case .eidAlAdha:
            return FastTagAbout(
                id: "warning-eid-al-adha",
                title: "Eid al-Adha",
                aboutText: "Fasting on Eid al-Adha is generally not practiced.",
                showsScheduleNote: false
            )
        case .tashreeq:
            return FastTagAbout(
                id: "warning-tashreeq",
                title: "Days of Tashreeq",
                aboutText: "The days of Tashreeq (11–13 Dhul Hijjah) are generally not fasted.",
                showsScheduleNote: false
            )
        }
    }
}

struct AboutTagSheet: View {
    let about: FastTagAbout

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let subtitle = about.subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(about.aboutText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    if !about.bullets.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("When it applies")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(about.bullets, id: \.self) { bullet in
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(bullet)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if about.showsScheduleNote {
                        Text("This does not change your alarm schedule.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .navigationTitle(about.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
